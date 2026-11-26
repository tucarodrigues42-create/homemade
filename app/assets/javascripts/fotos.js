// Fotos dos pedidos: antes de enviar, o celular reduz cada foto (no máximo
// 1600 px, JPEG). Assim uma foto de 4 MB vira uns 300 KB, o envio fica rápido
// mesmo no 4G e o banco de dados não enche.
(function () {
  if (window.__homemadeFotos) return;
  window.__homemadeFotos = true;

  var LADO_MAXIMO = 1600;
  var QUALIDADE = 0.82;
  var LIMITE_ENVIO = 4 * 1024 * 1024; // limite de cada envio na hospedagem

  function carregar(arquivo) {
    if (window.createImageBitmap) {
      return createImageBitmap(arquivo, { imageOrientation: "from-image" }).catch(function () { return carregarImg(arquivo); });
    }
    return carregarImg(arquivo);
  }

  function carregarImg(arquivo) {
    return new Promise(function (ok, erro) {
      var url = URL.createObjectURL(arquivo);
      var img = new Image();
      img.onload = function () { ok(img); };
      img.onerror = function () { URL.revokeObjectURL(url); erro(new Error("imagem")); };
      img.src = url;
    });
  }

  function reduzir(arquivo) {
    if (!/^image\//.test(arquivo.type) || arquivo.type === "image/gif") return Promise.resolve(arquivo);
    return carregar(arquivo).then(function (img) {
      var largura = img.width, altura = img.height;
      var escala = Math.min(1, LADO_MAXIMO / Math.max(largura, altura));
      var canvas = document.createElement("canvas");
      canvas.width = Math.round(largura * escala);
      canvas.height = Math.round(altura * escala);
      var ctx = canvas.getContext("2d");
      ctx.fillStyle = "#fff";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      return new Promise(function (ok) {
        canvas.toBlob(function (blob) {
          if (!blob || (blob.size >= arquivo.size && /^image\/(jpeg|png|webp)$/.test(arquivo.type))) return ok(arquivo);
          var nome = (arquivo.name || "foto").replace(/\.[^.]+$/, "") + ".jpg";
          ok(new File([blob], nome, { type: "image/jpeg", lastModified: Date.now() }));
        }, "image/jpeg", QUALIDADE);
      });
    }).catch(function () { return arquivo; });
  }

  function trocarArquivos(input, arquivos) {
    try {
      var dt = new DataTransfer();
      arquivos.forEach(function (a) { dt.items.add(a); });
      input.files = dt.files;
      return true;
    } catch (e) {
      return false;
    }
  }

  function mostrarPrevia(input, arquivos) {
    var caixa = input.closest(".campo") && input.closest(".campo").querySelector("[data-fotos-previa]");
    if (!caixa) return;
    caixa.innerHTML = "";
    caixa.hidden = arquivos.length === 0;
    arquivos.forEach(function (a) {
      var img = document.createElement("img");
      img.src = URL.createObjectURL(a);
      img.alt = a.name;
      caixa.appendChild(img);
    });
    if (arquivos.length) {
      var texto = document.createElement("p");
      texto.className = "discreto";
      texto.textContent = arquivos.length + (arquivos.length === 1 ? " foto será anexada" : " fotos serão anexadas") + " ao salvar.";
      caixa.appendChild(texto);
    }
  }

  function rotulo(input, texto) {
    var span = input.closest("label") && input.closest("label").querySelector("span");
    if (span) {
      if (!span.dataset.original) span.dataset.original = span.textContent;
      span.textContent = texto || span.dataset.original;
    }
  }

  document.addEventListener("change", function (e) {
    var input = e.target;
    if (!input.matches || !input.matches("[data-fotos-envio], [data-fotos-campo]")) return;
    var originais = Array.prototype.slice.call(input.files || []);
    if (!originais.length) { mostrarPrevia(input, []); return; }

    rotulo(input, "Preparando fotos…");
    var form = input.form;
    var botoes = form ? form.querySelectorAll("[type=submit]") : [];
    botoes.forEach(function (b) { b.disabled = true; });

    Promise.all(originais.map(reduzir)).then(function (arquivos) {
      trocarArquivos(input, arquivos);
      var total = arquivos.reduce(function (s, a) { return s + a.size; }, 0);
      botoes.forEach(function (b) { b.disabled = false; });
      if (total > LIMITE_ENVIO) {
        rotulo(input, "Fotos pesadas demais: escolha menos de cada vez");
        input.value = "";
        mostrarPrevia(input, []);
        return;
      }
      if (input.matches("[data-fotos-envio]")) {
        rotulo(input, "Enviando " + arquivos.length + (arquivos.length === 1 ? " foto…" : " fotos…"));
        if (form.requestSubmit) form.requestSubmit(); else form.submit();
      } else {
        rotulo(input);
        mostrarPrevia(input, arquivos);
      }
    });
  });
})();
