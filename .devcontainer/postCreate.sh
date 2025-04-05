#!/bin/bash
echo "Setting up OCaml environment for vscode user..."

# Defina a versão do OCaml que você deseja usar
OCAML_VERSION="5.2.1"
# Ou use uma versão mais recente: OCAML_VERSION="5.1.1"

# Garante que estamos no diretório home do usuário para opam init
cd /home/vscode || exit

# Inicializa o opam para o usuário vscode.
# '--disable-sandboxing' é frequentemente necessário em containers.
# '-a' responde sim automaticamente para modificação de scripts de shell (ex: .bashrc)
opam init --disable-sandboxing -y -a

# Cria o switch OCaml se ele não existir
# Usar '|| true' para não falhar se o switch já existir de um rebuild anterior
opam switch create $OCAML_VERSION -y || true
# Garante que estamos usando o switch correto
opam switch $OCAML_VERSION

# Instalar as bibliotecas necessárias
opam install dune csv ounit ounit2 sqlite3 lwt ocurl tls conduit-lwt-unix lwt_ssl -y

eval $(opam env)
