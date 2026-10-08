using System.Security.Claims;
using IntegraApi.Data;
using IntegraApi.Dtos;
using IntegraApi.Models;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Endpoints;

// Endpoints de solicitações internas (Quadro 8 do PIM, seção 6.5).
public static class SolicitacoesEndpoints
{
    public static void MapSolicitacoesEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/solicitacoes")
            .RequireAuthorization()
            .WithTags("Solicitações");

        grupo.MapGet("/", ListarAsync);
        grupo.MapGet("/{id:int}", DetalharAsync);
        grupo.MapPost("/", CriarAsync);
        grupo.MapPut("/{id:int}/cancelamento", CancelarAsync);
    }

    private static string? UserId(ClaimsPrincipal p) =>
        p.FindFirstValue(ClaimTypes.NameIdentifier) ?? p.FindFirstValue("sub");

    private static async Task<IResult> ListarAsync(
        ApplicationDbContext db, ClaimsPrincipal principal,
        string? status, int page = 1, int pageSize = 20)
    {
        if (page < 1 || pageSize is < 1 or > 100)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["page/pageSize"] = ["page deve ser >= 1 e pageSize entre 1 e 100."]
            });

        var userId = UserId(principal);
        var query = db.Solicitacoes.Include(s => s.Responsavel)
            .Where(s => s.SolicitanteId == userId);

        if (!string.IsNullOrWhiteSpace(status) &&
            Enum.TryParse<StatusSolicitacao>(status, true, out var statusEnum))
        {
            query = query.Where(s => s.Status == statusEnum);
        }

        var total = await query.CountAsync();
        var itens = await query
            .OrderByDescending(s => s.CriadoEm)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => s.ToResponse())
            .ToListAsync();

        return Results.Ok(new PagedResponse<SolicitacaoResponse>(itens, page, pageSize, total));
    }

    private static async Task<IResult> DetalharAsync(int id, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var s = await db.Solicitacoes.Include(x => x.Responsavel)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (s is null) return Results.NotFound();
        if (s.SolicitanteId != userId) return Results.Forbid();

        return Results.Ok(s.ToResponse());
    }

    private static async Task<IResult> CriarAsync(
        CriarSolicitacaoRequest req, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal)!;

        // Idempotência: se o clientRequestId já foi recebido, devolve o registro existente
        // em vez de criar duplicado (seção 5.5 do PIM; PERES, 2026, p. 208).
        var existente = await db.Solicitacoes
            .Include(s => s.Responsavel)
            .FirstOrDefaultAsync(s => s.ClientRequestId == req.ClientRequestId);
        if (existente is not null)
            return Results.Ok(existente.ToResponse());

        if (string.IsNullOrWhiteSpace(req.Titulo))
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["titulo"] = ["Informe o título da solicitação."]
            });

        var protocolo = $"SOL-{DateTime.UtcNow.Ticks % 1_000_000:D6}";

        var solicitacao = new Solicitacao
        {
            ClientRequestId = req.ClientRequestId,
            Protocolo = protocolo,
            Titulo = req.Titulo,
            Categoria = req.Categoria,
            Prioridade = req.Prioridade,
            Descricao = req.Descricao,
            Status = StatusSolicitacao.Aberta,
            SolicitanteId = userId
        };

        db.Solicitacoes.Add(solicitacao);
        await db.SaveChangesAsync();

        return Results.Created($"/api/solicitacoes/{solicitacao.Id}", solicitacao.ToResponse());
    }

    private static async Task<IResult> CancelarAsync(int id, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var s = await db.Solicitacoes.FirstOrDefaultAsync(x => x.Id == id);
        if (s is null) return Results.NotFound();
        if (s.SolicitanteId != userId) return Results.Forbid();

        if (s.Status != StatusSolicitacao.Aberta)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["status"] = ["Só é possível cancelar solicitações com status \"Aberta\"."]
            });

        s.Status = StatusSolicitacao.Cancelada;
        s.AtualizadoEm = DateTime.UtcNow;
        await db.SaveChangesAsync();

        return Results.Ok(s.ToResponse());
    }
}
