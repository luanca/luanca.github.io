// Criado por Luan Carvalho

function idade() {
  // Sintaxe da variável idade: "ano-mes-dia"
  var nascimento = "1999-05-10";
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
  document.getElementById("idadeExtenso").innerHTML = idade + " " + vi9;
}
idade();