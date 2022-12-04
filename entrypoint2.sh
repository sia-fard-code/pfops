#! /bin/sh

path_meta=/workspace/metadata/
path_mani=/workspace/manifest/
path_temp=/workspace/manifest-temp/
config_file=${1:-"config.yaml"}
bootstrap=${2:-"false"}

if [[ "$bootstrap" == "true" ]]
then
	# create cluster directories
	mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p yq 'env(path) + .clusters.metadata[].name' $config_file; done)

	# generate cluster metadata
	path=$path_meta yq '{"cluster": .clusters.metadata[] | pick(["repo", "revision", "name", "namespace", "server"]) }' $config_file -s 'env(path) + .cluster.name + "/cluster"'
	# generate cluster manifest
	yq '{"cluster": .clusters.manifest }' $config_file | ytt -f "$path_temp"clusters.yaml --data-values-file=-  --output-files "$path_mani"bootstrap/
fi
i=0
cluster_len=$(yq '.clusters.metadata | length' $config_file)
while [[ $i -lt $cluster_len ]]; do
	if [[ "$bootstrap" == "true" ]]
	then

	# generate env manifest
		i=$i yq '{
			"env": .clusters.metadata[env(i)].envs.manifest 
			+ {"namespace": .clusters.manifest.namespace, 
				"server": .clusters.metadata[env(i)].server, 
				"workflow" : .clusters.metadata[env(i)].workflow,
				"cluster" : .clusters.metadata[env(i)].name,
				"pfops_revision" : .clusters.metadata[env(i)].revision,
				"pfops_repo" : .clusters.metadata[env(i)].repo
			} 
			| pick(["workflow", "pfops_revision", "pfops_repo", "repo", "revision", "name", "cluster", "namespace", "server"]) 
			}' $config_file > /var/tmp/env_config
		ytt -f "$path_temp"envs.yaml --data-values-file=/var/tmp/env_config  --output-files $(path=$path_mani i=$i yq 'env(path) + .clusters.metadata[env(i)].name' $config_file)
		ytt -f "$path_temp"pfops/ --data-values-file=/var/tmp/env_config  --output-files $(path=$path_mani i=$i yq 'env(path) + .clusters.metadata[env(i)].name' $config_file)/pfops
	else
	# create env directories
		mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p i=$i yq 'env(path) + .clusters.metadata[env(i)].name + "/" + .clusters.metadata[env(i)].envs.metadata[].name' $config_file; done)
	# generate env metadata
		path=$path_meta i=$i yq '{
			"env": .clusters.metadata[env(i)].envs.metadata[] 
			+ {"cluster" : .clusters.metadata[env(i)].name
			} 
			| pick(["repo", "revision", "name", "cluster"]) 
			}' $config_file -s 'env(path) + .env.cluster + "/" + .env.name + "/env"'

		j=0
		env_len=$(i=$i yq '.clusters.metadata[env(i)].envs.metadata | length' $config_file)
		while [[ "$j" -lt $env_len && "$bootstrap" == "false" ]]; do
	# create app directories
			mkdir -p $(for p in $(echo -e "$path_meta $path_mani"); do path=$p i=$i j=$j yq 'env(path) + .clusters.metadata[env(i)].name + "/" + .clusters.metadata[env(i)].envs.metadata[env(j)].name + "/apps/" + .clusters.metadata[env(i)].envs.metadata[env(j)].apps.metadata[].name' $config_file; done)

	# generate app metadata
			path=$path_meta i=$i j=$j yq '{
				"app": .clusters.metadata[env(i)].envs.metadata[env(j)].apps.metadata[] 
				+ {"cluster" : .clusters.metadata[env(i)].name, 
					"env" : .clusters.metadata[env(i)].envs.metadata[env(j)].name
				} 
				| pick(["repo", "revision", "name", "cluster", "env", "sync_wave"]) 
				}' $config_file -s 'env(path) + .app.cluster + "/" + .app.env + "/apps/" + .app.name + "/app"'
	# generate app manifest
			i=$i j=$j yq '{
				"app": .clusters.metadata[env(i)].envs.metadata[env(j)].apps.manifest 
				+ {"namespace": .clusters.manifest.namespace, 
					"server": .clusters.metadata[env(i)].server,
					"cluster" : .clusters.metadata[env(i)].name, 
					"env" : .clusters.metadata[env(i)].envs.metadata[env(j)].name
				} 
				| pick(["repo", "revision", "name", "cluster", "env", "namespace", "server"]) 
				}' $config_file | ytt -f "$path_temp"apps.yaml --data-values-file=-  --output-files $(path=$path_mani i=$i j=$j yq 'env(path) + .clusters.metadata[env(i)].name + "/" + .clusters.metadata[env(i)].envs.metadata[env(j)].name' $config_file)

			k=0
			app_len=$(i=$i j=$j yq '.clusters.metadata[env(i)].envs.metadata[env(j)].apps.metadata | length' $config_file)
			while [ $k -lt $app_len ]; do
	# generate kustomize manifest
				i=$i j=$j k=$k yq '{
					"app": .clusters.metadata[env(i)].envs.metadata[env(j)].apps.metadata[env(k)] 
					+ { "namespace": .clusters.manifest.namespace,
					    "cluster" : .clusters.metadata[env(i)].name, 
						"server": .clusters.metadata[env(i)].server,
						"env" : .clusters.metadata[env(i)].envs.metadata[env(j)].name} 
					}' $config_file | ytt -f "$path_temp"base/ --data-values-file=-  --output-files $(path=$path_mani i=$i j=$j k=$k yq 'env(path) + .clusters.metadata[env(i)].name + "/" + .clusters.metadata[env(i)].envs.metadata[env(j)].name + "/apps/" + .clusters.metadata[env(i)].envs.metadata[env(j)].apps.metadata[env(k)].name' $config_file)
				k=$(($k+1))
			done
			j=$(($j+1))
		done
	fi
	i=$(($i+1))
done
