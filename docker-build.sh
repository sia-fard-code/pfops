docker build -t siavashghf2000/pfops . -f Dockerfile.pfops
docker build -t siavashghf2000/argocd . -f Dockerfile.argocd

docker push siavashghf2000/argocd
docker push siavashghf2000/pfops
