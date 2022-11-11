// Criado por Luan Carvalho
var EBIC = "img/certificados/"; // Endereço Base de Imagens de Certificados
var certificados = [
    ["Entrevista de Emprego na Prática: Como mostrar o seu valor para conquistar a vaga ideal", "Gupy", "06-20-2022", "Certificado Entrevista de Emprego na Prática _ Luan de Carvalho Santos.jpg", "", ""],
    ["Fundamentos de TI: Hardware e Software", "Fundação Bradesco", "09-10-2022", "Certificado FUNDAMENTOS DE TI HARDWARE E SOFTWARE.jpg", "https://www.ev.org.br/validar-certificado", "FC2ECB75-133D-444F-9B14-AC735039A36E"]
];

function listarCertificado(TagId) {
    var texto = "";
    var mes = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
    certificados.forEach(certificado => {
        var data1 = new Date(certificado[2]);
        var data2 = data1.getDate() + " de " + mes[data1.getMonth()] + " de " + data1.getFullYear();
        texto += "<li><img src=\"" + EBIC + certificado[3] + "\" /><div><h2>" + certificado[0] + "</h2><span><b>" + certificado[1] + "</b> | " + data2 + "</span>";
        if (certificado[5] !== "") {
            texto += "<a"
            if (certificado[4] !== "") {
                texto += " href=\"" + certificado[4] + "\"";
            }
            texto += ">Ver credencial: " + certificado[5] + "</a>";
        }
        texto += "</div></li>"
    });
    document.getElementById(TagId).innerHTML = texto;
}

listarCertificado("listaCert");