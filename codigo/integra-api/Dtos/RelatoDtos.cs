using System.ComponentModel.DataAnnotations;
using IntegraApi.Models;

namespace IntegraApi.Dtos;

public record CriarRelatoRequest(
    [Required] DateOnly Data,
    [Required, MaxLength(80)] string Contexto,
    [Required, MaxLength(4000)] string Descricao,
    [Required] bool CienciaConfirmada
);

public record RelatoResponse(
    int Id, DateOnly Data, string Contexto, string Status,
    string? RetornoAoAutor, DateTime CriadoEm
);

public static class RelatoMapper
{
    public static RelatoResponse ToResponse(this RelatoReservado r) => new(
        r.Id, r.Data, r.Contexto, r.Status.ToString(), r.RetornoAoAutor, r.CriadoEm
    );
}
