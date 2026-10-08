using System.ComponentModel.DataAnnotations;
using IntegraApi.Models;

namespace IntegraApi.Dtos;

public record CriarSolicitacaoRequest(
    [Required] string ClientRequestId,
    [Required, MaxLength(150)] string Titulo,
    [Required, MaxLength(60)] string Categoria,
    PrioridadeSolicitacao Prioridade,
    [Required, MaxLength(2000)] string Descricao
);

public record SolicitacaoResponse(
    int Id,
    string Protocolo,
    string Titulo,
    string Categoria,
    string Prioridade,
    string Descricao,
    string Status,
    string? ResponsavelNome,
    DateTime CriadoEm,
    DateTime AtualizadoEm
);

public record PagedResponse<T>(IEnumerable<T> Itens, int Pagina, int TamanhoPagina, int Total);

public static class SolicitacaoMapper
{
    public static SolicitacaoResponse ToResponse(this Solicitacao s) => new(
        s.Id, s.Protocolo, s.Titulo, s.Categoria, s.Prioridade.ToString(), s.Descricao,
        s.Status.ToString(), s.Responsavel?.NomeCompleto, s.CriadoEm, s.AtualizadoEm
    );
}
