using System.Security.Claims;
using IntegraApi.Data;
using IntegraApi.Dtos;
using IntegraApi.Models;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Endpoints;

// Endpoints de participação na formação: progresso, conclusão e avaliação (Quadro 8).
public static class ParticipacoesEndpoints
{
    public static void MapParticipacoesEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/participacoes")
            .RequireAuthorization()
            .WithTags("Participações");

        grupo.MapGet("/minhas", MinhasAsync);
        grupo.MapPost("/", ConcluirAsync);
        grupo.MapPost("/{id:int}/avaliacao", AvaliarAsync);
    }

    private static string? UserId(ClaimsPrincipal p) =>
        p.FindFirstValue(ClaimTypes.NameIdentifier) ?? p.FindFirstValue("sub");

    private static async Task<IResult> MinhasAsync(ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var itens = await db.Participacoes
            .Include(p => p.Conteudo)
            .Where(p => p.ColaboradorId == userId)
            .OrderByDescending(p => p.CriadoEm)
            .Select(p => p.ToResponse())
            .ToListAsync();

        return Results.Ok(itens);
    }

    private static async Task<IResult> ConcluirAsync(
        ConcluirParticipacaoRequest req, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal)!;

        // Idempotência igual à de solicitações (seção 5.5 do PIM).
        var existente = await db.Participacoes
            .Include(p => p.Conteudo)
            .FirstOrDefaultAsync(p => p.ClientRequestId == req.ClientRequestId);
        if (existente is not null)
            return Results.Ok(existente.ToResponse());

        var conteudo = await db.ConteudosFormativos.FindAsync(req.ConteudoId);
        if (conteudo is null)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["conteudoId"] = ["Conteúdo não encontrado."]
            });

        var participacao = new Participacao
        {
            ClientRequestId = req.ClientRequestId,
            ColaboradorId = userId,
            ConteudoId = req.ConteudoId,
            Concluido = true,
            ConcluidoEm = DateTime.UtcNow
        };

        db.Participacoes.Add(participacao);
        await db.SaveChangesAsync();
        participacao.Conteudo = conteudo;

        return Results.Created($"/api/participacoes/{participacao.Id}", participacao.ToResponse());
    }

    private static async Task<IResult> AvaliarAsync(
        int id, AvaliacaoRequest req, ApplicationDbContext db, ClaimsPrincipal principal)
    {
        var userId = UserId(principal);
        var participacao = await db.Participacoes.FirstOrDefaultAsync(p => p.Id == id);
        if (participacao is null) return Results.NotFound();
        if (participacao.ColaboradorId != userId) return Results.Forbid();

        var respostas = req.Respostas.ToList();
        if (respostas.Count == 0)
            return Results.ValidationProblem(new Dictionary<string, string[]>
            {
                ["respostas"] = ["Informe ao menos uma resposta."]
            });

        // Nota simples: média das respostas (0-10), só para fins de demonstração.
        var nota = Math.Round((decimal)respostas.Average(), 1);
        participacao.Nota = nota;
        await db.SaveChangesAsync();

        return Results.Ok(new AvaliacaoResponse(nota, nota >= 7));
    }
}
