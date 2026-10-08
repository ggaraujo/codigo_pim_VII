using System.Security.Claims;
using IntegraApi.Data;
using IntegraApi.Dtos;
using IntegraApi.Models;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Endpoints;

// Endpoints de relato reservado (Quadro 8, seção 4.3). Não anônimo; só o próprio
// autor acessa seus relatos por aqui — a leitura pelo RH/inclusão é feita no painel.
public static class RelatosEndpoints
{
    public static void MapRelatosEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/relatos")
            .RequireAuthorization()
            .WithTags("Relatos");

        grupo.MapPost("/", CriarAsync);
        grupo.MapGet("/meus", MeusAsync);
        grupo.MapGet("/{id:int}", DetalharAsync);
    }

    private static string? UserId(ClaimsPrincipal p) =>
        p.FindFirstValue(ClaimTypes.NameIdentifier) ?? p.FindFirstValue("sub");

    private static async Task<IResult> CriarAsync(
        CriarRelatoRequest req, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        if (!req.CienciaConfirmada)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["cienciaConfirmada"] = ["É necessário confirmar ciência de que o relato não é anônimo."]
            });

        var relato = new RelatoReservado
        {
            AutorId = UserId(principal)!,
            Data = req.Data,
            Contexto = req.Contexto,
            Descricao = req.Descricao,
            CienciaConfirmada = req.CienciaConfirmada,
            Status = StatusRelato.Recebido
        };

        db.RelatosReservados.Add(relato);
        await db.SaveChangesAsync();

        return Results.Created($"/api/relatos/{relato.Id}", relato.ToResponse());
    }

    private static async Task<IResult> MeusAsync(ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var itens = await db.RelatosReservados
            .Where(r => r.AutorId == userId)
            .OrderByDescending(r => r.CriadoEm)
            .Select(r => r.ToResponse())
            .ToListAsync();

        return Results.Ok(itens);
    }

    private static async Task<IResult> DetalharAsync(int id, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var r = await db.RelatosReservados.FirstOrDefaultAsync(x => x.Id == id);
        if (r is null) return Results.NotFound();
        if (r.AutorId != userId) return Results.Forbid();

        return Results.Ok(r.ToResponse());
    }
}
