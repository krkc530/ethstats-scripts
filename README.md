# ethstats-scripts

## Install
```bash
git clone --recursive https://github.com/krkc530/ethstats-scripts
```

## Run server
```bash
./run.sh server
```

## Run Client
```bash
./client.sh --rpc-host="[YOUR_HOST]" --rpc-port="[YOUR_PORT]"
```

## Run all (server, 4 clients) for test purpose
To run this, checkout nodes.cfg
```bash
./run_all.sh
```

## Reset
Removes all containers and images from ethstats
```bash
./reset.sh
```
