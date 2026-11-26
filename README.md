# Homemade Confeitaria · Sistema de gestão

Sistema web da **Homemade Confeitaria** (Arapiraca – AL) para organizar a agenda de
encomendas e entregas, os clientes (com atalho para o WhatsApp), os endereços de
entrega, os produtos e os ingredientes. Funciona no navegador do celular ou do computador.

![Logo Homemade](app/assets/images/homemade-logo-terracota.svg)

## O que o sistema faz

- **Painel**: pedidos de hoje, valor a receber, produção do dia, pedidos da semana, agenda e alertas de validade e estoque.
- **Pedidos**: cliente (cadastrado ou não), WhatsApp, entrega ou retirada com endereço, data e horário, itens escolhidos do cadastro de produtos ou escritos à mão (com quantidade, preço e observação), descrição longa, taxa de entrega, desconto e total automático. Etapas (novo → confirmado → em produção → pronto → entregue, ou cancelado) e pagamento (pago ou a receber) mudam com um toque. Busca por nome, WhatsApp, item ou número, filtros por dia, entrega/retirada, pagamento e etapa, e botão que manda o resumo do pedido no WhatsApp do cliente.
- **Etapas do pedido**: cada pedido tem um botão colorido com a etapa atual. Ao tocar nele, abrem todas as etapas (Novo, Confirmado, Em produção, Pronto, Entregue/Retirado e Cancelado) e é só escolher. A barrinha mostra em que ponto o pedido está, e o pagamento muda com "Marcar pago" (ou "A receber"/"Pago" na tela do pedido). Depois de cada mudança aparece um aviso com o botão **Desfazer**.
- **Fotos no pedido**: anexe fotos de referência (bolo, decoração, print da conversa) ao criar o pedido ou na tela dele. O celular reduz cada foto antes de enviar, e elas ficam guardadas no banco de dados.
- **Backup e planilhas** (menu Mais): planilhas CSV de clientes, pedidos e itens (todos ou de um período), que abrem no Excel e no Google Planilhas; cópia completa em .json (clientes, endereços, pedidos, itens, produtos, ingredientes e agenda) e restauração dessa cópia pelo administrador. Restaurar nunca apaga nada: o que está no arquivo volta e o que foi criado depois continua. Fotos, usuários e senhas não entram no arquivo.
- **Dashboard de faturamento** (menu Mais): faturamento de hoje, da semana e do mês, comparação com o mês anterior, ticket médio, recebido x a receber, gráfico de evolução por dias, semanas ou meses (com tabela) e produtos que mais vendem. Cancelados não entram.
- **Produção do dia**: soma, produto por produto, tudo o que precisa ser feito nos pedidos do dia (cancelados ficam de fora), com opção de contar só o que falta entregar e de imprimir.
- **Agenda**: compromissos com data, horário e descrição longa, agrupados por dia, com filtro por data e botão "Hoje".
- **Clientes**: nome, WhatsApp (obrigatório), telefone fixo e e-mail opcionais, busca por nome ou número e botão que abre a conversa no WhatsApp.
- **Endereços**: cadastrados junto com o cliente (já vem Arapiraca – AL). Cliente sem endereço aparece como "Retira na loja".
- **Produtos e ingredientes**: preço, estoque, fabricação e validade, com aviso de produto vencido.
- **Usuários**: login obrigatório. O administrador cadastra e remove a equipe; cada pessoa pode trocar a própria senha.

## Rodar no computador

Precisa de Ruby 3.3.

```bash
bundle install
bin/rails db:prepare   # cria o banco e o administrador
bin/rails server
```

Abra http://localhost:3000 e entre com:

- E-mail: `admin@homemade.com`
- Senha: `homemade123`

**Troque a senha no primeiro acesso** (Usuários › Editar). Para criar o administrador com outro
e-mail e senha, defina `ADMIN_EMAIL` e `ADMIN_SENHA` antes de rodar `bin/rails db:prepare`.

## Testes

```bash
bin/rails test
```

## Colocar no ar

O sistema usa SQLite, então o servidor precisa de um disco permanente para a pasta `storage/`
(onde fica o banco). Configure no servidor:

- `RAILS_ENV=production`
- `SECRET_KEY_BASE` (gere com `bin/rails secret`)
- `ADMIN_EMAIL` e `ADMIN_SENHA` (opcional)

Comandos: `bundle install`, `bin/rails assets:precompile`, `bin/rails db:prepare` e `bin/rails server`.

## Créditos

Este sistema é baseado no projeto **Doceria Dona Torta**, desenvolvido por
[Edvaldo H. L.](https://github.com/EdvaldoHLeite), [Hermyson C. M. O.](https://github.com/Hermyson) e
[Laisy C. F. S.](https://github.com/laisy) para a disciplina de Engenharia de Software (2020.4) do curso de
Ciência da Computação da Universidade Federal do Agreste de Pernambuco (UFAPE), sob orientação do
Prof. Dr. Rodrigo Cardoso Amaral de Andrade. Código original:
[Projeto-ES-Doceria/Doceria_Dona_Torta](https://github.com/Projeto-ES-Doceria/Doceria_Dona_Torta).
Os documentos do projeto acadêmico estão em [`docs/academico`](docs/academico).

Adaptação para a Homemade Confeitaria: nova identidade visual, textos em português,
atualização para Ruby 3.3 / Rails 7.2, login obrigatório e correções de bugs.

A parte de pedidos usa ideias do projeto [Alon's Bakery OMS](https://github.com/Artumax9/alons-bakery-oms)
(© 2026 Arturo Paredes, licença MIT): preço de cada item copiado no momento do pedido, cálculo do total
num objeto separado e etapas do pedido controladas por uma tabela de transições permitidas. O código foi
reescrito em português para este sistema; o aviso de licença MIT original segue abaixo.

<details><summary>Licença MIT – Alon's Bakery OMS</summary>

```
MIT License

Copyright (c) 2026 Arturo Paredes

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
</details>
