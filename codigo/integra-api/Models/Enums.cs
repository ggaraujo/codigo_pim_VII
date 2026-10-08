namespace IntegraApi.Models;

public enum StatusSolicitacao
{
    Aberta,
    EmAndamento,
    Concluida,
    Cancelada
}

public enum PrioridadeSolicitacao
{
    Baixa,
    Media,
    Alta
}

public enum StatusRelato
{
    Recebido,
    EmAcolhimento,
    EmAnalise,
    Encaminhado,
    Concluido
}
