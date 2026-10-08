using System.ComponentModel.DataAnnotations;

namespace IntegraApi.Models;

// Solicitação interna registrada por um colaborador (Figura 5 — modelo de dados do PIM, seção 6.1).
public class Solicitacao
{
    public int Id { get; set; }

    // Identificador público mostrado ao colaborador (ex.: "SOL-000128").
    public string Protocolo { get; set; } = string.Empty;

    // Chave de idempotência enviada pelo app para evitar duplicidade em reenvios
    // (PERES, 2026, p. 208; seção 5.5 do PIM).
    [Required]
    public string ClientRequestId { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string Titulo { get; set; } = string.Empty;

    [Required, MaxLength(60)]
    public string Categoria { get; set; } = string.Empty;

    public PrioridadeSolicitacao Prioridade { get; set; } = PrioridadeSolicitacao.Media;

    [Required, MaxLength(2000)]
    public string Descricao { get; set; } = string.Empty;

    public StatusSolicitacao Status { get; set; } = StatusSolicitacao.Aberta;

    [Required]
    public string SolicitanteId { get; set; } = string.Empty;
    public ApplicationUser? Solicitante { get; set; }

    public string? ResponsavelId { get; set; }
    public ApplicationUser? Responsavel { get; set; }

    public string? Observacao { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
    public DateTime AtualizadoEm { get; set; } = DateTime.UtcNow;

    // Token de versão oculto citado no Quadro 8 e na Figura 6 (concorrência otimista
    // quando o gestor edita status/responsável/observação no painel).
    [Timestamp]
    public byte[]? RowVersion { get; set; }
}
