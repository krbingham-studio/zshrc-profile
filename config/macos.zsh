# macOS-specific configuration
# This file is only loaded on macOS systems

# Work-specific aliases (MSMG)
alias cashback='cd ~/Git/msmg-private/cashback'
alias qplatform='cd ~/Git/msmg-private/cashback/qplatform'
alias customer='cd ~/Git/msmg-private/customer'
alias platform='cd ~/Git/msmg-private/platform'
alias msmgPrivate='cd ~/Git/msmg-private/'
alias msmgExternal='cd ~/Git/msmg-external/'
alias msmgSandbox='cd ~/Git/msmg-sandbox/'
alias tools='cd ~/Git/msmg-private/cashback/cashback-quidco-tools'
alias localdev='cd ~/Git/msmg-private/cashback/cashback-quidco-local-dev'

export INFRA_PATH="$HOME/Git/msmg-private/cashback/quidco-legacy-infrastructure"

# Certificate setup - only when needed
setup_certs() {
  export CERT_DIR="/Users/$USER/.ca_certs"
  export CERT_PATH="$CERT_DIR/cert.pem"
  export NODE_EXTRA_CA_CERTS="$CERT_DIR/ZscalerRootCertificate-2048-SHA256.crt"
  export SSL_CERT_FILE="$CERT_PATH"
  export SSL_CERT_DIR="$CERT_DIR/"
  export REQUESTS_CA_BUNDLE="$CERT_PATH"
  export AWS_CA_BUNDLE="$CERT_DIR/cert.pem"
}
[ -d "/Users/$USER/.ca_certs" ] && setup_certs
