# Remove finalizers from all Alloy resources
kubectl get alloys.collectors.grafana.com -n observability-client -o name | xargs -I {} kubectl patch {} -n observability-client -p '{"metadata":{"finalizers":[]}}' --type=merge

# Remove finalizers from all Helm releases
kubectl get helmreleases.helm.toolkit.fluxcd.io -n observability-client -o name | xargs -I {} kubectl patch {} -n observability-client -p '{"metadata":{"finalizers":[]}}' --type=merge