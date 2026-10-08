using IntegraApi.Data;
using IntegraApi.Dtos;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Endpoints;

// Endpoints do acervo de conteúdos formativos (Quadro 8, seção 5.5 — cache local no app).
public static class ConteudosEndpoints
{
    public static void MapConteudosEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/conteudos")
            .RequireAuthorization()
            .WithTags("Conteúdos");

        grupo.MapGet("/", ListarAsync);
        grupo.MapGet("/{id:int}", DetalharAsync);
    }

    private static async Task<IResult> ListarAsync(
        ApplicationDbContext db, string? modulo, DateTime? atualizadoDesde, int page = 1, int pageSize = 20)
    {
        var query = db.ConteudosFormativos.AsQueryable();

        if (!string.IsNullOrWhiteSpace(modulo))
            query = query.Where(c => c.Modulo == modulo);

        if (atualizadoDesde.HasValue)
            query = query.Where(c => c.AtualizadoEm >= atualizadoDesde.Value);

        var total = await query.CountAsync();
        var itens = await query
            .OrderBy(c => c.Modulo)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => c.ToResponse())
            .ToListAsync();

        return Results.Ok(new PagedResponse<ConteudoResponse>(itens, page, pageSize, total));
    }

    private static async Task<IResult> DetalharAsync(int id, ApplicationDbContext db)
    {
        var c = await db.ConteudosFormativos.FindAsync(id);
        return c is null ? Results.NotFound() : Results.Ok(c.ToDetalheResponse());
    }
}
