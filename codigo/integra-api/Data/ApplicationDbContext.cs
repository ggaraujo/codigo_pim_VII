using IntegraApi.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace IntegraApi.Data;

// IdentityDbContext com SQLite, como especificado no capítulo 6 do PIM
// (EF Core + SQLite + ASP.NET Core Identity).
public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<Solicitacao> Solicitacoes => Set<Solicitacao>();
    public DbSet<ConteudoFormativo> ConteudosFormativos => Set<ConteudoFormativo>();
    public DbSet<Participacao> Participacoes => Set<Participacao>();
    public DbSet<RelatoReservado> RelatosReservados => Set<RelatoReservado>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Solicitacao>(e =>
        {
            e.HasIndex(s => s.ClientRequestId).IsUnique();
            e.HasIndex(s => s.Protocolo).IsUnique();
            e.HasOne(s => s.Solicitante)
                .WithMany()
                .HasForeignKey(s => s.SolicitanteId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(s => s.Responsavel)
                .WithMany()
                .HasForeignKey(s => s.ResponsavelId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Participacao>(e =>
        {
            e.HasIndex(p => p.ClientRequestId).IsUnique();
            e.HasOne(p => p.Colaborador)
                .WithMany()
                .HasForeignKey(p => p.ColaboradorId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasOne(p => p.Conteudo)
                .WithMany(c => c.Participacoes)
                .HasForeignKey(p => p.ConteudoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<RelatoReservado>(e =>
        {
            e.HasOne(r => r.Autor)
                .WithMany()
                .HasForeignKey(r => r.AutorId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<RefreshToken>(e =>
        {
            e.HasIndex(t => t.Token).IsUnique();
            e.HasOne(t => t.User)
                .WithMany(u => u.RefreshTokens)
                .HasForeignKey(t => t.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
