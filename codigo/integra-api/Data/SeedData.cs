using IntegraApi.Models;
using Microsoft.AspNetCore.Identity;

namespace IntegraApi.Data;

// Popula papéis, usuários de exemplo e módulos de formação na primeira execução.
// As senhas abaixo são só para ambiente de desenvolvimento/demonstração — nunca
// usar senhas fixas como estas em produção (seção 6.3 do PIM trata disso).
public static class SeedData
{
    public static readonly string[] Papeis = { "Colaborador", "Gestor", "RHInclusao", "AdminTecnico" };

    public static async Task AplicarAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        await db.Database.EnsureCreatedAsync();

        foreach (var papel in Papeis)
        {
            if (!await roleManager.RoleExistsAsync(papel))
                await roleManager.CreateAsync(new IdentityRole(papel));
        }

        await CriarUsuarioSeNaoExisteAsync(userManager, "colaborador@conecta.com.br", "Colaborador123!",
            "Ana Souza", "Atendimento", "Colaborador");
        await CriarUsuarioSeNaoExisteAsync(userManager, "gestor@conecta.com.br", "Gestor123!",
            "Bruno Lima", "Operações", "Gestor");
        await CriarUsuarioSeNaoExisteAsync(userManager, "rh@conecta.com.br", "RhInclusao123!",
            "Carla Dias", "RH/Inclusão", "RHInclusao");
        await CriarUsuarioSeNaoExisteAsync(userManager, "admin@conecta.com.br", "AdminTec123!",
            "Diego Fontes", "TI", "AdminTecnico");

        if (!db.ConteudosFormativos.Any())
        {
            db.ConteudosFormativos.AddRange(
                new ConteudoFormativo
                {
                    Titulo = "Conceitos: raça, etnia, preconceito, discriminação e racismo institucional",
                    Modulo = "1. Conceitos",
                    DuracaoMinutos = 120,
                    Conteudo = "Microconteúdos sobre os conceitos fundamentais, seguidos de encontro dialogado " +
                        "com o RH/inclusão (TOLEDO-PLAÇA, 2023, p. 9-23; 48-50)."
                },
                new ConteudoFormativo
                {
                    Titulo = "História e cultura afro-brasileira, africana e indígena",
                    Modulo = "2. História e cultura",
                    DuracaoMinutos = 180,
                    Conteudo = "Acervo cultural e roda de conversa com filme ou música indicados pelo livro " +
                        "(TOLEDO-PLAÇA, 2023, p. 66-82; 98)."
                },
                new ConteudoFormativo
                {
                    Titulo = "Estereótipos e representatividade no trabalho",
                    Modulo = "3. Estereótipos e representatividade",
                    DuracaoMinutos = 120,
                    Conteudo = "Casos fictícios de discriminação no ambiente de trabalho e discussão sobre " +
                        "representatividade (TOLEDO-PLAÇA, 2023, p. 31; 91-104)."
                },
                new ConteudoFormativo
                {
                    Titulo = "Acolhimento e papel das lideranças",
                    Modulo = "4. Acolhimento",
                    DuracaoMinutos = 180,
                    Conteudo = "Simulação do fluxo do relato reservado e papel das lideranças no acolhimento " +
                        "(TOLEDO-PLAÇA, 2023, p. 58-64; 105-107)."
                }
            );
            await db.SaveChangesAsync();
        }
    }

    private static async Task CriarUsuarioSeNaoExisteAsync(
        UserManager<ApplicationUser> userManager, string email, string senha,
        string nomeCompleto, string area, string papel)
    {
        if (await userManager.FindByEmailAsync(email) is not null) return;

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            EmailConfirmed = true,
            NomeCompleto = nomeCompleto,
            Area = area,
            Ativo = true
        };

        var resultado = await userManager.CreateAsync(user, senha);
        if (resultado.Succeeded)
            await userManager.AddToRoleAsync(user, papel);
    }
}
