using System.ComponentModel.DataAnnotations;

namespace IntegraApi.Dtos;

public record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Senha
);

public record RefreshRequest([Required] string RefreshToken);

public record TokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiraEm,
    PerfilResponse Perfil
);

public record PerfilResponse(
    string Id,
    string NomeCompleto,
    string Email,
    string Area,
    IEnumerable<string> Papeis
);
