kubectl apply -f pfops-plugins-cm.yaml
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install sia-pfops argo/argo-cd -n argocd -f argocd-value.yaml 
kubectl apply -f pfops-app.yaml 