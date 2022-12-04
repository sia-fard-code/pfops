#! /bin/sh

path_meta=/workspace/metadata/
path_mani=/workspace/manifests/
path_temp=/workspace/manifest-temp/
config_file=${1:-"config.yaml"}
bootstrap=${2:-"false"}

if [[ "$bootstrap" == "true" ]]
then
	# create cluster directories
	mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p yq 'env(path) + .clusters.metadata.name' $config_file; done)

	# generate cluster metadata
	path=$path_meta yq '{"cluster": .clusters.metadata | pick(["repo", "revision", "name", "namespace", "server"]) }' $config_file -s 'env(path) + .cluster.name + "/cluster"'
	# generate cluster manifest
	yq '{"cluster": .clusters.manifest }' $config_file | ytt -f "$path_temp"clusters.yaml --data-values-file=-  --output-files "$path_mani"bootstrap/
	# generate env manifest
	yq '{
		"env": .clusters.metadata.envs.manifest 
		+ {"namespace": .clusters.manifest.namespace, 
			"server": .clusters.metadata.server, 
			"workflow" : .clusters.metadata.workflow,
			"init" : .clusters.metadata.init,
			"cluster" : .clusters.metadata.name,
			"pfops_revision" : .clusters.metadata.revision,
			"pfops_repo" : .clusters.metadata.repo
		} 
		| pick(["init", "pfops", "workflow", "pfops_revision", "pfops_repo", "repo", "revision", "name", "cluster", "namespace", "server"]) 
		}' $config_file > /var/tmp/env_config
	ytt -f "$path_temp"envs.yaml --data-values-file=/var/tmp/env_config  --output-files $(path=$path_mani yq 'env(path) + .clusters.metadata.name' $config_file)
	ytt -f "$path_temp"pfops/ --data-values-file=/var/tmp/env_config  --output-files $(path=$path_mani yq 'env(path) + .clusters.metadata.name' $config_file)/pfops
else
# create env directories
	mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p yq 'env(path) + .cluster.name + "/" + .env.name' $config_file; done)
# generate env metadata
	path=$path_meta yq '{
		"env": .env 
		+ {"cluster" : .cluster.name
		} 
		| pick(["repo", "revision", "name", "cluster"]) 
		}' $config_file -s 'env(path) + .env.cluster + "/" + .env.name + "/env"'

# create app directories
	mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p yq 'env(path) + .cluster.name + "/" + .env.name + "/apps/" + .app.metadata.name' $config_file; done)

# generate app metadata
	path=$path_meta yq '{
		"app": .app.metadata 
		+ {"cluster" : .cluster.name, 
			"env" : .env.name
		} 
		| pick(["repo", "revision", "name", "cluster", "env", "sync_wave"]) 
		}' $config_file -s 'env(path) + .app.cluster + "/" + .app.env + "/apps/" + .app.name + "/app"'
# generate app manifest
	yq '{
		"app": .app.manifest 
		+ {"namespace": .cluster.namespace, 
			"server": .cluster.server,
			"cluster" : .cluster.name, 
			"default_ns": .env.default_ns,
			"override_na": .env.override_na,
			"env" : .env.name
		} 
		| pick(["repo", "revision", "name", "cluster", "env", "namespace", "server", "default_ns", "override_na"]) 
		}' $config_file | ytt -f "$path_temp"apps.yaml --data-values-file=-  --output-files $(path=$path_mani yq 'env(path) + .cluster.name + "/" + .env.name' $config_file)

# generate kustomize manifest
	yq '{
		"app": .app.metadata 
		+ { "namespace": .cluster.namespace,
			"cluster" : .cluster.name, 
			"server": .cluster.server,
			"default_ns": .env.default_ns,
			"override_na": .env.override_na,
			"env" : .env.name} 
		}' $config_file | ytt -f "$path_temp"base/ --data-values-file=-  --output-files $(path=$path_mani yq 'env(path) + .cluster.name + "/" + .env.name + "/apps/" + .app.metadata.name' $config_file)
fi
