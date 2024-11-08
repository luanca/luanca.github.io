// Criado por Luan Cavalho em 08.11.2024 às 01:58

const perguntas = {
    "1": {
        "pergunta": "O dia do mês em que você nasceu aparece neste calendário?",
        "status": "Pergunta 1 de 9",
        "paragrafo": "Há um calendário nesta página. Verifique esse calendário e responda a pergunta usando um dos botões abaixo.",
        "calendarioTipo": "Dia"
    },
    "2": {
        "pergunta": "Este calendário mostra o dia do mês do seu nascimento?",
        "status": "Pergunta 2 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Dia"
    },
    "3": {
        "pergunta": "O dia do mês em que você nasceu visível neste calendário?",
        "status": "Pergunta 3 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Dia"
    },
    "4": {
        "pergunta": "Consegue ver o dia do mês do seu nascimento neste calendário?",
        "status": "Pergunta 4 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Dia"
    },
    "5": {
        "pergunta": "Neste calendário é possível ver o dia do mês em que você nasceu?",
        "status": "Pergunta 5 de 9",
        "paragrafo": "Última pergunta sobre o dia! Responda-a usando um dos botôes abaixo.",
        "calendarioTipo": "Dia"
    },
    "6": {
        "pergunta": "O mês do seu nascimento está neste calendário?",
        "status": "Pergunta 6 de 9",
        "paragrafo": "Agora o calendário está exibindo os meses do ano. Verifique esse calendário e responda a pergunta usando um dos botões abaixo.",
        "calendarioTipo": "Mes"
    },
    "7": {
        "pergunta": "É possível ver o mês do seu nascimento neste calendário?",
        "status": "Pergunta 7 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Mes"
    },
    "8": {
        "pergunta": "O mês em que você nasceu está entre os meses visíveis neste calendário?",
        "status": "Pergunta 8 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Mes"
    },
    "9": {
        "pergunta": "O mês do seu nascimento aparece neste calendário?",
        "status": "Pergunta 9 de 9",
        "paragrafo": "Responda usando um dos botôes abaixo.",
        "calendarioTipo": "Mes"
    }
}

// Elementos gerais
const paginaElementos = {
    "botaoInicio": document.getElementById("btComecar"),
    "botaoRespSim": document.getElementById("btRespostaSim"),
    "botaoRespNao": document.getElementById("btRespostaNao"),
    "botaoFim": document.getElementById("btFim"),
    "tagPrincipal": document.getElementById("elementoTotal"),
    "tagPainelEsquerdo": document.getElementById("elementoPainelEsquerdo"),
    "tagPainelDireito": document.getElementById("elementoPainelDireito"),
    "tagCalendarios": document.getElementById("elementoCalendario"),
    "tagCalendarioDia": document.getElementById("elementoCalendarioDia"),
    "tagCalendarioMes": document.getElementById("elementoCalendarioMes"),
    "tagPergStatus": document.getElementById("status"),
    "tagPergPergunta": document.getElementById("pergunta"),
    "tagPergParagrafo": document.getElementById("paragrafoPergunta"),
    "tagResposta": document.getElementById("textoResultado"),
    "tagMensagemResposta": document.getElementById("resultado"),
    "tagEmojiResposta": document.getElementById("emojiResultado")
};
const telasParametros = ["Inicio", "Pergunta", "Resposta"];
const calendarioParametros = ["dia", "mes"];
const mesNome = ["algum mês entre janeiro e dezembro (você respondeu errado!)", "janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
var pergunta = {
    "perguntaAtual": 0,
    "perguntaPeso": {
        "1": 1,
        "2": 2,
        "3": 4,
        "4": 8,
        "5": 16,
        "6": 1,
        "7": 2,
        "8": 4,
        "9": 8
    },
};
var resposta = {
    "Dia": 0,
    "Mes": 0,
    "UsuarioEstaTentandoEnganar": 0,
    "Indicacao": ["certo", "errado"],
    "Emoji": ["🎉", "🤦"]
};

// Roteiros
function iniciar() {
    // Iniciar as perguntas
    pergunta.perguntaAtual = 0;
    resposta.Dia = 0;
    resposta.Mes = 0;
    telasParametros.forEach(parametro => {
        paginaElementos.tagPrincipal.classList.remove(parametro);
    });
    paginaElementos.tagPrincipal.classList.add("Pergunta");
    calendarioParametros.forEach(parametro => {
        paginaElementos.tagCalendarios.classList.remove(parametro);
    });
    respondido(0);
};
function respondido(respostaUsuario) {
    // Processando resposta do usuário
    if (pergunta.perguntaAtual != 0) {
        // Caso não seja a primeira pergunta
        if (respostaUsuario == 1) {
            // Usuario respondeu SIM
            resposta[perguntas[pergunta.perguntaAtual]["calendarioTipo"]] += pergunta.perguntaPeso[pergunta.perguntaAtual];
        };
        paginaElementos.tagCalendarios.classList.remove(perguntas[pergunta.perguntaAtual]["calendarioTipo"]);
        paginaElementos.tagCalendarioDia.classList.remove("perg" + pergunta.perguntaAtual);
        paginaElementos.tagCalendarioMes.classList.remove("perg" + pergunta.perguntaAtual);
    };
    pergunta.perguntaAtual++;
    if (pergunta.perguntaAtual > 9) {
        // Sem mais perguntas
        finalizar();
    } else {
        // Proxima pergunta
        paginaElementos.tagCalendarios.classList.add(perguntas[pergunta.perguntaAtual]["calendarioTipo"]);
        paginaElementos.tagCalendarioDia.classList.add("perg" + pergunta.perguntaAtual);
        paginaElementos.tagCalendarioMes.classList.add("perg" + pergunta.perguntaAtual);
        paginaElementos.tagPergStatus.innerText = perguntas[pergunta.perguntaAtual]["status"];
        paginaElementos.tagPergPergunta.innerText = perguntas[pergunta.perguntaAtual]["pergunta"];
        paginaElementos.tagPergParagrafo.innerText = perguntas[pergunta.perguntaAtual]["paragrafo"];
    }
};
function finalizar() {
    // Finalizar perguntas
    telasParametros.forEach(parametro => {
        paginaElementos.tagPrincipal.classList.remove(parametro);
    });
    resposta.Indicacao.forEach(parametro => {
        paginaElementos.tagMensagemResposta.classList.remove(parametro);
    });
    var textoResposta = "";
    resposta.UsuarioEstaTentandoEnganar = 0;
    if (resposta.Dia == 0 || resposta.Dia > 31) {
        textoResposta += "Algum dia";
        resposta.UsuarioEstaTentandoEnganar = 1;
    } else {
        textoResposta += resposta.Dia;
    }
    textoResposta += " de ";
    if (resposta.Mes <= 12) {
        textoResposta += mesNome[resposta.Mes];
    } else {
        textoResposta += mesNome[0];
        resposta.UsuarioEstaTentandoEnganar = 1;
    }
    paginaElementos.tagResposta.innerText = textoResposta;
    paginaElementos.tagMensagemResposta.classList.add(resposta.Indicacao[resposta.UsuarioEstaTentandoEnganar]);
    paginaElementos.tagEmojiResposta.innerText = resposta.Emoji[resposta.UsuarioEstaTentandoEnganar];
    paginaElementos.tagPrincipal.classList.add("Resposta");
};
function retornar() {
    // Voltar ao início
    telasParametros.forEach(parametro => {
        paginaElementos.tagPrincipal.classList.remove(parametro);
    });
    paginaElementos.tagPrincipal.classList.add("Inicio");
}

// Eventos
paginaElementos.botaoInicio.addEventListener("click", iniciar);
paginaElementos.botaoFim.addEventListener("click", retornar);
paginaElementos.botaoRespNao.addEventListener("click", function() {respondido(0)});
paginaElementos.botaoRespSim.addEventListener("click", function() {respondido(1)});