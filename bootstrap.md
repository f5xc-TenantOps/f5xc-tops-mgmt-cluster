# 🥾 Bootstrap

## Install microk8s
```shell
sudo snap install microk8s --classic --channel=latest/stable
sudo usermod -a -G microk8s $USER
mkdir -p ~/.kube
chmod 0700 ~/.kube
su - $USER
```

## Enable microk8s addons
```shell
microk8s enable hostpath-storage
sudo apt-get install git
git config --global --add safe.directory /snap/microk8s/current/addons/community/.git
microk8s enable community
microk8s enable cert-manager
kubectl apply -f cert-manager-config.yml
kubectl apply -f coredns-config.yml
```

## Enable/Configure Ingress 
```shell
microk8s enable ingress:default-ssl-certificate=kube-system/wildcard-k11s-io
```

## Enable/Configure argocd
```shell
microk8s enable argocd
kubectl replace -f argocd-config.yml
kubectl apply -f argocd-ingress.yml
argocd account update-password --account <new-account-name> --current-password <admin-password> --new-password <new-account-password>
```

## Apply initial ArgoCD App
```shell
kubectl apply -f argocd/argocd-app.yml
```

## Prepare the ``tfc-operator-system`` NS
```shell
export NAMESPACE=tfc-operator-system
kubectl create namespace $NAMESPACE
kubectl -n $NAMESPACE apply -f bootstrap-secrets.yml
```

