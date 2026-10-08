using System.ComponentModel.DataAnnotations;

namespace IntegraApi.Models;

// Participação de um colaborador em um módulo de formação (conclusão e avaliação).
public class Participacao
{
    public int Id { get; set; }

    [Required]
    public string ClientRequestId { get; set; } = string.Empty;

    [Required]
    public string ColaboradorId { get; set; } = string.Empty;
    public ApplicationUser? Colaborador { get; set; }

    public int ConteudoId { get; set; }
    public ConteudoFormativo? Conteudo { get; set; }

    public bool Concluido { get; set; }
    public DateTime? ConcluidoEm { get; set; }

    // Nota da avaliação (0-10), preenchida só depois de POST /avaliacao.
    public decimal? Nota { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
