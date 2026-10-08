using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using IntegraApi.Models;
using Microsoft.IdentityModel.Tokens;

namespace IntegraApi.Services;

// Gera o par de tokens de acesso/renovação descrito na Figura 3 do PIM
// (MONTEIRO, 2026, p. 106-108): token de acesso curto + token de renovação mais longo.
public class TokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config) => _config = config;

    public (string token, DateTime expiraEm) GerarAccessToken(ApplicationUser user, IEnumerable<string> papeis)
    {
        var minutos = _config.GetValue<int>("Jwt:AccessTokenMinutos", 15);
        var expiraEm = DateTime.UtcNow.AddMinutes(minutos);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new("nome", user.NomeCompleto),
            new("area", user.Area),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        claims.AddRange(papeis.Select(p => new Claim(ClaimTypes.Role, p)));

        var chave = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var credenciais = new SigningCredentials(chave, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expiraEm,
            signingCredentials: credenciais
        );

        return (new JwtSecurityTokenHandler().WriteToken(token), expiraEm);
    }

    public string GerarRefreshToken()
    {
        var bytes = RandomNumberGenerator.GetBytes(64);
        return Convert.ToBase64String(bytes);
    }
}
