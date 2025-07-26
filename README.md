# Remove finalizers from all Alloy resources
kubectl get alloys.collectors.grafana.com -n observability-client -o name | xargs -I {} kubectl patch {} -n observability-client -p '{"metadata":{"finalizers":[]}}' --type=merge

# Remove finalizers from all Helm releases
kubectl get helmreleases.helm.toolkit.fluxcd.io -n observability-client -o name | xargs -I {} kubectl patch {} -n observability-client -p '{"metadata":{"finalizers":[]}}' --type=merge

# Posthog note

Pageview funnel, by browser
 
https://eu.posthog.com/project/67142/dashboard/212700

Convention rate from Visitors to Client
Need to know what is desired Third Page View ( Register, KYC, .... ? or smt)