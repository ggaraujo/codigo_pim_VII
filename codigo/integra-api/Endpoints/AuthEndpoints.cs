using System.Security.Claims;
using IntegraApi.Data;
using IntegraApi.Dtos;
using IntegraApi.Models;
using IntegraApi.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Endpoints;

// Endpoints de autenticação (Quadro 8 do PIM): login, refresh, logout e me.
public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/auth").WithTags("Autenticação");

        grupo.MapPost("/login", LoginAsync)
            .RequireRateLimiting("login") // limite de tentativas -> 429 (PERES, 2026, p. 188)
            .WithName("Login");

        grupo.MapPost("/refresh", RefreshAsync).WithName("Refresh");

        grupo.MapPost("/logout", LogoutAsync)
            .RequireAuthorization()
            .WithName("Logout");

        grupo.MapGet("/me", MeAsync)
            .RequireAuthorization()
            .WithName("Me");
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest req,
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext db,
        TokenService tokenService)
    {
        var user = await userManager.FindByEmailAsync(req.Email);
        if (user is null || !user.Ativo)
            return Results.Unauthorized();

        var senhaOk = await userManager.CheckPasswordAsync(user, req.Senha);
        if (!senhaOk)
            return Results.Unauthorized();

        var papeis = await userManager.GetRolesAsync(user);
        var (accessToken, expiraEm) = tokenService.GerarAccessToken(user, papeis);
        var refreshToken = tokenService.GerarRefreshToken();

        db.RefreshTokens.Add(new RefreshToken
        {
            Token = refreshToken,
            UserId = user.Id,
            ExpiraEm = DateTime.UtcNow.AddDays(7)
        });
        await db.SaveChangesAsync();

        var perfil = new PerfilResponse(user.Id, user.NomeCompleto, user.Email!, user.Area, papeis);
        return Results.Ok(new TokenResponse(accessToken, refreshToken, expiraEm, perfil));
    }

    private static async Task<IResult> RefreshAsync(
        RefreshRequest req,
        ApplicationDbContext db,
        UserManager<ApplicationUser> userManager,
        TokenService tokenService)
    {
        var tokenAtual = await db.RefreshTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.Token == req.RefreshToken);

        if (tokenAtual is null || !tokenAtual.EstaAtivo || tokenAtual.User is null)
            return Results.Unauthorized();

        // Rotação: revoga o token usado e emite um novo par.
        tokenAtual.RevogadoEm = DateTime.UtcNow;

        var papeis = await userManager.GetRolesAsync(tokenAtual.User);
        var (accessToken, expiraEm) = tokenService.GerarAccessToken(tokenAtual.User, papeis);
        var novoRefresh = tokenService.GerarRefreshToken();

        db.RefreshTokens.Add(new RefreshToken
        {
            Token = novoRefresh,
            UserId = tokenAtual.User.Id,
            ExpiraEm = DateTime.UtcNow.AddDays(7)
        });
        await db.SaveChangesAsync();

        var perfil = new PerfilResponse(
            tokenAtual.User.Id, tokenAtual.User.NomeCompleto, tokenAtual.User.Email!,
            tokenAtual.User.Area, papeis);
        return Results.Ok(new TokenResponse(accessToken, novoRefresh, expiraEm, perfil));
    }

    private static async Task<IResult> LogoutAsync(
        RefreshRequest req, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? principal.FindFirstValue("sub");
        var token = await db.RefreshTokens
            .FirstOrDefaultAsync(t => t.Token == req.RefreshToken && t.UserId == userId);
        if (token is not null)
        {
            token.RevogadoEm = DateTime.UtcNow;
            await db.SaveChangesAsync();
        }
        return Results.NoContent();
    }

    private static async Task<IResult> MeAsync(ClaimsPrincipal principal, UserManager<ApplicationUser> userManager)
    {
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier) ?? principal.FindFirstValue("sub");
        if (userId is null) return Results.Unauthorized();

        var user = await userManager.FindByIdAsync(userId);
        if (user is null) return Results.Unauthorized();

        var papeis = await userManager.GetRolesAsync(user);
        return Results.Ok(new PerfilResponse(user.Id, user.NomeCompleto, user.Email!, user.Area, papeis));
    }
}
