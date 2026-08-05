package main

deny[msg] {
    input.kind == "Deployment"
    image := input.spec.template.spec.containers[_].image
    startswith(image, "latest")
    msg := sprintf("Image '%s' uses 'latest' tag, which is forbidden by policy.", [image])
}

deny[msg] {
    input.kind == "HelmRelease" # Или аналог для вашего движка
    not startswith(input.spec.chart.spec.sourceRef.name, "oci://")
    msg := "All Helm charts must be sourced from an OCI registry."
}
