# 🚀 Projeto Monitoramento de Servidor Nginx na AWS

Este projeto automatiza o monitoramento e notificação via webhook para servidores, utilizando NGINX e AWS. Foi proposto como primeiro projeto no programa de bolsas da UOL COMPASS trilha DevSecOps.

---

## 📦 Instalação

```bash
# Clone o repositório
git clone https://github.com/Ruan-Pablo-Oli/Nginx-with-monitoration.git
cd Nginx-with-monitoration
```

---

## 🛠️ Dependências

- NGINX
- AWS Account
- jq
- curl
- unzip

---

## ⚙️ Configuração AWS

#### 1. **Criação da VPC**
   
   **Primeiro passo: criar a VPC que será utilizada no projeto.**
   
   - Acesse o serviço VPC no console da AWS
   - No menu lateral, acesse a opção "Your VPCs"
   - Clique em "Create VPC" 
   - Configure as seguintes opções: 
      - VPC only
      - IPv4 CIDR manual input
      - No IPv6 CIDR block
      - Tenancy default
   - Adicione um name tag para identificação da VPC

   <img src="assets/Criandovpc.gif" width="500" />


#### 2. **Criação das Subnets**
   
   **Segundo passo: criar as subnets para a VPC criada anteriormente.**

   - Acesse a opção "Subnets" no menu lateral do console AWS e clique em "Create subnet"
   - Selecione a VPC criada anteriormente
   - **Dica:** Primeiro escolha a região onde a VPC será criada, depois nomeie de acordo com essa região
   - **Dica:** Escolha zonas de disponibilidade diferentes para as subnets quando possível
   - Configure o IP da subnet (exemplo: 10.0.1.0/20)
   - Clique em "Create subnet"
   - Crie mais 3 subnets com IPs de rede diferentes (próxima subnet: 10.0.2.0/20)

   <img src="assets/subnet.gif" width="500" />


#### 3. **Criação do Internet Gateway**

   **Terceiro passo: criar o Internet Gateway para que as subnets públicas tenham acesso à internet.**

   - Acesse a opção "Internet Gateways" e clique em "Create Internet Gateway"
   - Adicione um name tag para identificação
   - Clique em "Create Internet Gateway"


#### 4. **Criação da Route Table**

   **Quarto passo: definir route tables para as subnets. Este processo será dividido em duas partes.**

   ##### 4.1 (Criando route table e associando com internet gateway)

   - Acesse a opção "Route Tables" no menu lateral
   - Clique em "Create route table"
   - Adicione um name tag e selecione a VPC criada no primeiro passo
   - Clique em "Create route table"
   - No campo "Routes", clique em "Edit routes"
   - Clique em "Add route"
   - Para o destino, escolha 0.0.0.0/0 (pacotes que acessarão a internet)
   - Escolha a opção "Internet Gateway" e selecione o gateway criado anteriormente
   - Salve as alterações

   ##### 4.2 (Associando subnets à route table)

   - Saia do campo "Routes" e acesse "Subnet associations"
   - Clique em "Edit subnet associations"
   - Escolha as duas subnets que serão públicas
   - Salve as associações
   - Para subnets privadas que precisam se comunicar entre si, crie uma tabela sem internet gateway e as associe

   <img src="assets/routeTable.gif" width="500" />

#### 5. **Criação do Security Group**

   **Quinto passo: criar o security group para permitir acesso SSH e HTTP ao serviço.**

   - Acesse a opção "Security Groups" na seção Security
   - Clique em "Create security group"
   - Adicione nome, descrição e escolha a VPC criada no primeiro passo
   - Crie duas regras Inbound: uma para SSH e outra para HTTP
   - Em "Source", configure "My IP" para restringir acesso apenas ao seu IP
   - Nas "Outbound rules", altere o destination da regra existente para "My IP"

   <img src="assets/securityGroup.gif" width="500" />


#### 6. **Bucket S3**
   **Criação do bucket com os arquivos que o user data utilizará para automatizar a configuração da instância.**

   ##### 6.1 (Criação do bucket)

   - Acesse o serviço S3 no console AWS
   - Clique em "Create bucket"
   - Configure as opções padrão, alterando apenas "Bucket Key" para "Disable"
   - Nomeie o bucket conforme necessário
   - Como será utilizado SSE-S3 para criptografia, não é necessário manter o Bucket Key habilitado

   ⚠️ **Importante:** Será necessário atualizar o nome do bucket no script user data conforme o nome escolhido.
   
   - No arquivo user data, altere os nomes dos buckets de acordo com o nome escolhido

   ![mudar_nome_bucket](assets/image.png)

   ##### 6.2 (Upload dos arquivos)
   - Acesse o bucket criado para fazer upload dos arquivos
   - No campo "Objects", clique em "Upload"
   - Faça upload dos arquivos: monitoramento.sh, index.html e styles.css
   - Mantenha todas as opções padrão e clique em "Upload"

   **Nota:** É possível fazer upload usando AWS CLI, porém utilizaremos o método mais simples via console.

   <img src="assets/bucket.gif" width="500" />

#### 7. **Secrets Manager**

   ##### Obtendo o webhook do Discord

   **Como obter o webhook do Discord:**
   
   1. **Acesse o servidor Discord** onde possui permissões de administrador
   2. **Vá para Configurações do Servidor** (clique com botão direito no nome do servidor)
   3. **Acesse "Integrações"** no menu lateral
   4. **Clique em "Webhooks"** e depois em "Criar Webhook"
   5. **Configure o webhook:**
      - Defina o nome do webhook (ex: "Monitor Nginx")
      - Selecione o canal onde as notificações aparecerão
      - Copie a **URL do Webhook**
   6. **Salve as configurações**

   ⚠️ **Importante:** Mantenha a URL do webhook segura - qualquer pessoa com acesso pode enviar mensagens para o servidor.

   **Configuração do AWS Secrets Manager:**

   - Acesse o serviço "Secrets Manager" no console AWS
   - Clique em "Store a new Secret"
   - Selecione a opção "Other type of secret"
   - **Importante:** Mantenha o nome e configuração do secret conforme especificado para o funcionamento do monitoramento.sh
   - A chave deve ser "webhook" e o valor deve ser o webhook obtido do Discord
   - Clique em "Next" e defina o secret name como exatamente "discord/webhook-api"
   - Clique em "Next", não configure rotation e finalize a criação do secret
   
   **Exemplo:**   

     ```json
     {
       "webhook":"https://discord.com/api/webhooks/xxx/yyy"
     }
     ```


   <img src="assets/secret.gif" width="500" />








#### 8. **Permissões IAM**

   **Criação das roles para que a instância EC2 possa acessar os arquivos do bucket e o secret.**

   - Acesse o serviço IAM no console AWS
   - Clique em "Roles"
   - Será criada uma role com duas policies: uma para acesso ao S3 e outra para acesso ao Secrets Manager
   - Clique em "Create role"
   - Selecione "AWS service" e escolha "EC2" em use case
   - Adicione as policies: "AmazonS3FullAccess" e "SecretsManagerReadWrite"
   - **Nota:** O ideal é seguir a política de menor privilégio com policies mais específicas, mas para ambiente de desenvolvimento, essa solução é adequada
   - Clique em "Next", adicione um nome e finalize clicando em "Create role"
   
   <img src="assets/CreateRole.gif" width="500" />

#### 9. **Criação da EC2 com Nginx usando User Data**

   **Passo final: criar uma instância EC2 utilizando user data para automatização.**
   
   - Acesse o serviço EC2 no console AWS
   - Entre na opção "Instances" e clique em "Launch instances"
   - Configure as tags necessárias
   - Selecione a AMI Ubuntu, instance type t2.micro
   - Use um key pair existente ou crie um novo para conexão SSH
   
   ##### 9.1 Configuração de rede
   **Utilizando a infraestrutura de rede criada anteriormente:**
   - Na seção "Network settings", clique em "Edit"
   - Escolha a VPC criada
   - Escolha uma das subnets públicas criadas
   - Mantenha "Auto-assign public IP" desabilitado (será usado Elastic IP)
   - Selecione "Select existing security group" e escolha o security group criado
   - Em "Configure storage", escolha o tamanho da instância
   - Abra "Advanced details" e em "IAM instance profile" selecione a role criada
   - Em "User data", utilize o arquivo user_data.sh do repositório ou copie o conteúdo
   - Clique em "Launch instance"
   
   ⚠️ **Importante:** Lembre-se de editar o nome do bucket no user data (obrigatório) e do webhook caso tenha sido criado com outro nome.
   
   <img src="assets/ec2.gif" width="500" />

#### 10. **Associando Elastic IP à EC2**
   **Atribuindo um IP público à instância EC2.**

   - Acesse "Elastic IPs" na seção "Network & Security"
   - Clique em "Allocate Elastic IP address"
   - Clique em "Allocate"
   - Selecione o IP alocado e clique em "Actions"
   - Clique em "Associate Elastic IP address"
   - Em "Instance", escolha a instância inicializada
   - Clique em "Associate"

   <img src="assets/ip.gif" width="500" />

---

## ⚙️ Funcionamento monitoramento.




---
## 🕒 Agendamentos Cron

- `monitoramento.sh` roda a cada minuto.
- Logs são limpos diariamente à meia-noite.

---

## 💡 Como Usar

- Acesse o IP público da instância para visualizar o status do monitoramento
- Consulte os logs em `/var/log/monitoramento_logs.txt`
- As notificações serão enviadas automaticamente para o Discord configurado

---

## 🔐 Segurança

⚠️ **Importante:**
- Nunca compartilhe credenciais AWS
- Mantenha webhooks do Discord privados
- Use IAM roles com menor privilégio possível
- Monitore os logs de acesso regularmente
- Configure adequadamente os Security Groups

---

## 📝 Contribuições

Contribuições são bem-vindas! Para contribuir:
1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 🤝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

---

## 📫 Contato

Para dúvidas ou sugestões, entre em contato através do GitHub Issues.

---

## 🙏 Agradecimentos

Projeto desenvolvido como parte do programa de bolsas UOL COMPASS - trilha DevSecOps.