build-docs:
  poetry run sphinx-build -b html docs/source docs/build

gen-apidocs:
  poetry run sphinx-apidoc --ext-doctest --ext-autodoc --ext-mathjax -f -o docs/source dataprep

black:
  poetry run black dataprep
  
ci: format ci-black typeck test lint

ci-black:
  poetry run black --check --quiet dataprep

format:
  poetry run black dataprep

typeck: ci-mypy

test:
  poetry run pytest dataprep

testf +ARGS="dataprep":
  poetry run pytest {{ARGS}}

lint:
  poetry run pylint dataprep

ci-mypy:
  poetry run mypy dataprep

build:
  poetry build

release version:
  #! /usr/bin/env bash

  # Sanity checks
  if [ ! -z "$(git status --porcelain)" ]; then echo "Git tree is not clean, commit first"; exit 1; fi

  if [ ! -z "$(git rev-parse --verify release)" ]; then echo "delete the existing release branch before new release"; exit 1; fi

  # Pre bump the version to get the next version number
  git checkout develop

  vstring="$(poetry version {{version}})"
  if [ $? -ne 0 ]; then
    echo $vstring;
    exit 1;
  fi
  
  from_version=$(echo "${vstring}" | sed -nr "s/^Bumping version from ([0-9]+\.[0-9]+\.[0-9]+) to ([0-9]+\.[0-9]+\.[0-9]+)$/\1/p")
  to_version=$(echo "${vstring}" | sed -nr "s/^Bumping version from ([0-9]+\.[0-9]+\.[0-9]+) to ([0-9]+\.[0-9]+\.[0-9]+)$/\2/p")

  git checkout pyproject.toml # clear up

  echo "Releasing from ${from_version} to ${to_version}?"
  select yn in "Yes" "No"; do
      case $yn in
          Yes ) break;;
          No ) git checkout pyproject.toml; git checkout develop; git branch -D release; exit;;
      esac
  done

  # Begin of the real stuff!

  # Create new release branch
  git checkout -b "release/v${to_version}" develop

  poetry version {{version}}
  
  echo "Creating release commit"
  git add pyproject.toml
  semantic-release version --{{version}}
  
  echo "Merge release/v${to_version} to master & develop"
  git checkout master
  git merge "release/v${to_version}"

  git checkout develop
  git merge "release/v${to_version}"

  echo "Push branch and tag to remote"
  git push origin master
  git push origin develop
  git push origin "release/v${to_version}"
  git push origin "v${to_version}"

  echo "Build artifacts"
  poetry build

  echo "Creating release draft"
  semantic-release changelog | sed "1iv${to_version}\n" | hub release create -d -a "dist/dataprep-${to_version}-py3-none-any.whl" -a "dist/dataprep-${to_version}.tar.gz" -F - "v${to_version}"

  


@ensure-git-clean:
  if [ ! -z "$(git status --porcelain)" ]; then echo "Git tree is not clean, commit first"; exit 1; fi



bench n m mem cpu target:
  docker run -it --rm -v $PWD/profiling:/profiling --memory={{mem}} --cpus={{cpu}} wooya/dataprep-profiling python /profiling/profiling.py --data=automobile --row={{n}} --col={{m}} --mem={{mem}} --cpu={{cpu}} {{target}}

benchall:
  #!/usr/bin/env python3
  import asyncio
  from asyncio import create_subprocess_shell

  async def run(cmd):
      proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
      )

      stdout, stderr = await proc.communicate()

      return stdout.splitlines()[-1].decode()

  async def bench(n: int, m: int, target: str):
      tasks = []
      for mem in ["1G", "2G", "4G", "8G"]:
          for cpu in [1, 2, 4, 8]:
              t = run(f"docker run -it --rm -v $PWD/profiling:/profiling --memory={mem} --cpus={cpu} wooya/dataprep-profiling python /profiling/profiling.py --data=automobile --row={n} --col={m} --mem={mem} --cpu={cpu} {target}")
              tasks.append(t)
      return await asyncio.gather(*tasks)
  
  for n in [1000000]:
      for m in [52]:
        for target in ["pandas", "dataprep"]:
            for x in asyncio.run(bench(n, m, target)):
                print(x)

