using System.ComponentModel.DataAnnotations;

namespace IntegraApi.Models;

// Relato reservado de discriminação. Não é anônimo — vinculado à conta do autor
// (seção 4.3 do PIM). Visível apenas ao próprio autor e ao RH/inclusão;
// o administrador técnico não tem acesso a este recurso pela API (Quadro 7).
public class RelatoReservado
{
    public int Id { get; set; }

    [Required]
    public string AutorId { get; set; } = string.Empty;
    public ApplicationUser? Autor { get; set; }

    [Required]
    public DateOnly Data { get; set; }

    [Required, MaxLength(80)]
    public string Contexto { get; set; } = string.Empty;

    [Required, MaxLength(4000)]
    public string Descricao { get; set; } = string.Empty;

    public bool CienciaConfirmada { get; set; }

    public StatusRelato Status { get; set; } = StatusRelato.Recebido;

    public string? RetornoAoAutor { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
    public DateTime AtualizadoEm { get; set; } = DateTime.UtcNow;
}
