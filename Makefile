.PHONY: terraform-fmt

PROJECTS=$(wildcard projects/*)

# Apply terraform auto-formatter: you should have this on editor save!
terraform-fmt:
	find projects -type d -exec terraform fmt {} \;
