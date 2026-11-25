# Homemade Confeitaria · Sistema de gestão

Sistema web da **Homemade Confeitaria** (Arapiraca – AL) para organizar a agenda de
encomendas e entregas, os clientes (com atalho para o WhatsApp), os endereços de
entrega, os produtos e os ingredientes. Funciona no navegador do celular ou do computador.

![Logo Homemade](app/assets/images/homemade-logo-terracota.svg)

## O que o sistema faz

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
