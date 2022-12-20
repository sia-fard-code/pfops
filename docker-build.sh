docker build -t siavashghf2000/pfops Dockerfile.pfops
docker build -t siavashghf2000/argocd Dockerfile.argocd

docker push siavashghf2000/argocd
docker push siavashghf2000/pfops
