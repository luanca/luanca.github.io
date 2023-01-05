// Criado por Luan Carvalho

function idade(nascimento) {
  // Sintaxe da variável idade: "ano-mes-dia"
  //var nascimento = "1999-05-10";
  var idade = 0;
  var vi1 = new Date();
  var vi2 = vi1.getFullYear()
  var vi3 = new Date(nascimento);
  var vi4 = vi3.getFullYear();
  idade = (vi2 - vi4) * 1;
  var vi5 = vi1.getMonth();
  var vi6 = vi3.getMonth();
  var vi7 = vi1.getDate();
  var vi8 = vi3.getDate();
  if (vi5 < vi6) {
    idade--;
  } else if (vi5 == vi6) {
    if (vi7 < vi8) {
      idade--;
    }
  }

  var vi9;
  if (idade > 1) {
    vi9 = "anos";
  } else {
    vi9 = "ano";
  }
  return idade + " " + vi9;
}

function preencher() {
  // função para preencher as informações na página
  var vp1, vp2;
  vp1 = new XMLHttpRequest();
  vp1.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      vp2 = JSON.parse(this.responseText);
      document.getElementById("nomeCurto").innerText = vp2.NomeCurto;
      document.title = document.title + ": " + vp2.NomeCurto;
      document.getElementById("nome").innerText = vp2.Nome;
      document.getElementById("fotoPerfil").src = vp2.FotoPerfil;
      document.getElementById("idade").innerHTML = "Idade: " + idade(vp2.DataNascimento.ano + "-" + vp2.DataNascimento.mes + "-" + vp2.DataNascimento.dia);
    }
  };
  vp1.open("GET", "perfil.json", true);
  vp1.send();
}

preencher();