using System.ComponentModel.DataAnnotations;

namespace IntegraApi.Models;

// Módulo de formação sobre diversidade étnico-racial (Quadro 6 do PIM).
public class ConteudoFormativo
{
    public int Id { get; set; }

    [Required, MaxLength(150)]
    public string Titulo { get; set; } = string.Empty;

    [Required, MaxLength(30)]
    public string Modulo { get; set; } = string.Empty; // ex.: "1. Conceitos"

    public int DuracaoMinutos { get; set; }

    [Required]
    public string Conteudo { get; set; } = string.Empty; // texto/markdown do módulo

    public DateTime AtualizadoEm { get; set; } = DateTime.UtcNow;

    public ICollection<Participacao> Participacoes { get; set; } = new List<Participacao>();
}
