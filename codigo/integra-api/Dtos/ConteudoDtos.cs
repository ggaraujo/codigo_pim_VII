using IntegraApi.Models;

namespace IntegraApi.Dtos;

public record ConteudoResponse(
    int Id, string Titulo, string Modulo, int DuracaoMinutos, DateTime AtualizadoEm
);

public record ConteudoDetalheResponse(
    int Id, string Titulo, string Modulo, int DuracaoMinutos, string Conteudo, DateTime AtualizadoEm
);

public static class ConteudoMapper
{
    public static ConteudoResponse ToResponse(this ConteudoFormativo c) =>
        new(c.Id, c.Titulo, c.Modulo, c.DuracaoMinutos, c.AtualizadoEm);

    public static ConteudoDetalheResponse ToDetalheResponse(this ConteudoFormativo c) =>
        new(c.Id, c.Titulo, c.Modulo, c.DuracaoMinutos, c.Conteudo, c.AtualizadoEm);
}
