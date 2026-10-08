using Microsoft.AspNetCore.Identity;

namespace IntegraApi.Models;

// Usuário do sistema (colaborador, gestor, RH/inclusão ou administrador técnico).
// Estende o IdentityUser do ASP.NET Core Identity com os campos específicos da Integra
// (PERES, 2026, p. 144-147 — Identity gerencia usuários, senhas com hash, papéis e claims).
public class ApplicationUser : IdentityUser
{
    public string NomeCompleto { get; set; } = string.Empty;

    // Área do colaborador (ex.: "Atendimento", "Financeiro", "Operações").
    // Usada como claim para delimitar o que um gestor pode ver (seção 6.3 do PIM).
    public string Area { get; set; } = string.Empty;

    public bool Ativo { get; set; } = true;

    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
}

// Token de renovação de sessão (Figura 3 do PIM: par de tokens curto/longo).
public class RefreshToken
{
    public int Id { get; set; }
    public string Token { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser? User { get; set; }
    public DateTime ExpiraEm { get; set; }
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
    public DateTime? RevogadoEm { get; set; }
    public bool EstaAtivo => RevogadoEm == null && ExpiraEm > DateTime.UtcNow;
}
