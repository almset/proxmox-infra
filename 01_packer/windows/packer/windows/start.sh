PACKER_LOG=1 packer init -var-file=../../config/prod.json windows-2022.pkr.hcl
PACKER_LOG=1 packer build -var-file=../../config/prod.json windows-2022.pkr.hcl
