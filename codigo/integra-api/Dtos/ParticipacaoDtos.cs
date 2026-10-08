using System.ComponentModel.DataAnnotations;
using IntegraApi.Models;

namespace IntegraApi.Dtos;

public record ConcluirParticipacaoRequest(
    [Required] string ClientRequestId,
    [Required] int ConteudoId
);

public record ParticipacaoResponse(
    int Id, int ConteudoId, string ConteudoTitulo, bool Concluido,
    DateTime? ConcluidoEm, decimal? Nota
);

public record AvaliacaoRequest(
    [Required, Range(0, 10)] IEnumerable<int> Respostas
);

public record AvaliacaoResponse(decimal Nota, bool Aprovado);

public static class ParticipacaoMapper
{
    public static ParticipacaoResponse ToResponse(this Participacao p) => new(
        p.Id, p.ConteudoId, p.Conteudo?.Titulo ?? string.Empty, p.Concluido, p.ConcluidoEm, p.Nota
    );
}
