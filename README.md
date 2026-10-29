# BloxGrindStudio

Base em Luau para Roblox Studio: interface por abas, farm de NPCs, missões, seleção de alvo, destaques visuais e viagem para pontos permitidos de um jogo próprio.

> Este projeto foi criado para uma experiência que você controla no Roblox Studio. Ele não é um executor nem injeta código no Blox Fruits de terceiros.

## Progresso

- [x] Estrutura inicial de repositório
- [x] Configuração compartilhada de dano, alvos, missões e destinos
- [x] GUI moderna com abas Overview, Farm, Visuals, Travel e Settings
- [x] Alternância de interface com RightShift
- [x] Cliente-servidor via RemoteEvent
- [x] Validação de ações, destinos, alvos e alcance no servidor
- [x] Farm com movimentação e ataque validados no servidor
- [x] Auto-quest com XP, Beli e progressão de nível de demonstração
- [x] Destaques locais para NPCs e itens do mapa próprio
- [x] Teleporte restrito a pontos predefinidos
- [x] Script de setup com destinos, itens e NPCs de demonstração
- [ ] Teste no Roblox Studio com NPCs rigged reais do seu place
- [ ] Ajustar catálogo de missões, recompensas e modelos do jogo
- [ ] Sincronizar com Rojo e publicar no GitHub

## Estrutura

- `default.project.json` — mapeamento para Rojo.
- `src/ReplicatedStorage/AutoGrindConfig.luau` — valores editáveis e catálogo de missões.
- `src/ServerScriptService/AutoGrindServer.server.luau` — validação, movimentação, dano e progressão.
- `src/StarterPlayer/StarterPlayerScripts/AutoGrindClient.client.luau` — interface e recursos visuais locais.
- `tools/StudioSetup.luau` — cria conteúdo de demonstração no Workspace.

## Instalação rápida

1. Instale [Rojo](https://rojo.space/) e o plugin Rojo correspondente no Roblox Studio.
2. Abra um terminal na pasta do repositório e execute `rojo serve`.
3. No Roblox Studio, conecte o plugin Rojo ao servidor para sincronizar scripts.
4. No Studio, abra **View → Command Bar**. Cole o conteúdo de `tools/StudioSetup.luau` e execute-o uma vez para gerar destinos, alvos e coletáveis de demonstração.
5. Pressione **Play**. A GUI deve aparecer no jogo; use **RightShift** para ocultar/mostrar.
6. Na aba **Farm**, ligue Auto Farm. Ligue Auto Quest para usar o catálogo de missões por nível.

Se não quiser usar Rojo, crie manualmente os objetos conforme `default.project.json`: ModuleScript `AutoGrindConfig` em ReplicatedStorage, Script `AutoGrindServer` em ServerScriptService e LocalScript `AutoGrindClient` em StarterPlayerScripts.

## Publicar no GitHub

Abra o terminal dentro de `BloxGrindStudio` e execute:

```powershell
git init
git add .
git commit -m "Initial BloxGrindStudio"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/BloxGrindStudio.git
git push -u origin main
```

Crie primeiro um repositório vazio no GitHub e substitua `SEU_USUARIO` pelo seu nome de usuário. Se você já iniciou um repositório local, não repita `git init` nem `git remote add origin`; confira o remoto com `git remote -v`.

## Configuração de NPCs e missões

NPCs elegíveis devem ficar em `Workspace/Enemies` e conter:

- Um `Humanoid`.
- Um `HumanoidRootPart`.
- Atributo booleano `AutoFarmTarget = true` ou tag CollectionService `FarmTarget`.
- Nome correspondente a `EnemyName` no catálogo para contar progresso de uma missão.

Para chefes, defina `IsBoss = true` ou adicione a tag `FarmBoss`. Ajuste nomes, níveis mínimos, XP, Beli, dano, alcance e cooldown em `AutoGrindConfig.luau`.

Os NPCs criados pelo setup são alvos visuais estacionários para validar a lógica de dano e o fluxo de interface. Troque-os por rigs animados que façam sentido para o mapa antes de usar em uma experiência real.

## Recursos

- **Overview:** nível, Beli, XP, missão e status.
- **Farm:** Auto Farm, Auto Quest, filtro Nearest/Boss.
- **Visuals:** destaques locais para NPCs e objetos em `Workspace/Collectibles`.
- **Travel:** teleportes a destinos fixos pré-configurados no servidor.
- **Settings:** parar todos os módulos e esconder a interface.
- **RightShift:** alternar a visibilidade da janela.

## Notas técnicas

- O sistema de XP/Beli cria `leaderstats` de demonstração quando eles não existem. Integre o código de recompensas à economia do seu próprio jogo antes de publicar.
- A movimentação usa `PathfindingService` e `Humanoid:MoveTo`; o mapa precisa ter uma malha navegável.
- O servidor decide o alvo, verifica distância e aplica dano. A GUI não pode escolher o dano ou conceder XP diretamente.
- O teleporte aceita apenas nomes cadastrados em `Config.Destinations` e pontos válidos em `Workspace/FarmDestinations`.
- **Verificação:** os arquivos foram gerados e conferidos quanto à presença. A execução final em Roblox Studio ainda precisa ser feita, pois o ambiente remoto desta sessão não oferece um runtime Roblox para testar a experiência.

## Referências

- [Blox-fruits-grinder — exemplo público de arquitetura para um jogo próprio](https://github.com/alimamys/Blox-fruits-grinder) — consultado como referência de organização; não copie código ou assets sem revisar a licença.
- [Roblox Creator Hub — RemoteEvents (PT-BR)](https://create.roblox.com/docs/pt-br/scripting/events/remote) — comunicação cliente/servidor e validação.
- [Roblox Creator Hub — Pathfinding](https://create.roblox.com/docs/characters/pathfinding) — navegação e criação de caminhos.

## Licença

MIT — veja `LICENSE`.
