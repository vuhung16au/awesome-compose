<!-- filepath: /Users/vuhung/Desktop/awesome-compose/wordpress-mariadb-kubernetes/README.md -->
# WordPress and MariaDB on Kubernetes

This project provides a complete setup for running WordPress with a MariaDB backend and phpMyAdmin on a Kubernetes cluster. It includes all necessary Kubernetes manifests for deploying the services, managing configurations, and securing sensitive data.

## Project Structure

The project is organized as follows:

```
wordpress-kubernetes
├── manifests
│   ├── wordpress
│   │   ├── deployment.yaml       # Deployment configuration for WordPress
│   │   └── service.yaml          # Service configuration for WordPress
│   ├── mariadb
│   │   ├── deployment.yaml       # Deployment configuration for MariaDB
│   │   ├── service.yaml          # Service configuration for MariaDB
│   │   └── pvc.yaml              # PersistentVolumeClaim for MariaDB
│   ├── phpmyadmin
│   │   ├── deployment.yaml       # Deployment configuration for phpMyAdmin
│   │   └── service.yaml          # Service configuration for phpMyAdmin
│   ├── configmaps
│   │   └── wordpress-config.yaml  # ConfigMap for WordPress configuration
│   └── secrets
│       └── db-credentials.yaml    # Secret for database credentials
├── kustomization.yaml             # Kustomize configuration file
└── README.md                      # Project documentation
```

## Beginner's Guide to Kubernetes Setup

### What You'll Need
- A Mac computer
- Basic familiarity with Terminal
- No prior Kubernetes knowledge required!

### Step 1: Install kubectl (The Kubernetes Command Tool)

This is the main tool you'll use to talk to your Kubernetes cluster. In your Terminal:

```bash
# Install kubectl using Homebrew
brew install kubectl

# Check if it installed correctly
kubectl version --client
```

You should see version information (don't worry if it says it can't connect to a server yet).

### Step 2: Choose a Kubernetes Environment

You have three main options for running Kubernetes on macOS. Choose the one that works best for you:

#### Option A: Docker Desktop (Easiest for Beginners)

If you already use Docker or prefer a graphical interface:

1. Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and install it
2. Open Docker Desktop
3. Click on the gear icon (⚙️) to open Settings
4. Select "Kubernetes" from the left sidebar
5. Check the box "Enable Kubernetes"
6. Click "Apply & Restart" (this may take several minutes)
7. When you see a green Kubernetes icon in the bottom status bar, your cluster is ready!

Verify it works:
```bash
kubectl get nodes
```
You should see one node called "docker-desktop" in the "Ready" state.

#### Option B: Minikube (Good for Learning)

Minikube runs a small Kubernetes cluster in a virtual machine:

```bash
# Install Minikube
brew install minikube

# Start a Kubernetes cluster with enough resources for WordPress
minikube start --cpus=2 --memory=4096mb --driver=docker

# Check if it's running
minikube status
```

You should see that the minikube host, kubelet, and apiserver are all "Running".

#### Option C: Kind (Lightweight Option)

Kind (Kubernetes in Docker) is lightweight but powerful:

```bash
# Install Kind
brew install kind

# Create a cluster with port forwarding for WordPress
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
EOF

# Create the cluster
kind create cluster --config kind-config.yaml

# Check if it's running
kubectl get nodes
```

### Step 3: Deploy WordPress and Related Services

Once you have a working Kubernetes environment (from any option above):

1. **Navigate to this project's directory**:
   ```bash
   cd wordpress-kubernetes
   ```

2. **Deploy everything at once**:
   ```bash
   kubectl apply -f manifests/ --recursive
   ```

3. **Watch the deployment progress**:
   ```bash
   kubectl get pods --watch
   ```
   
   Press Ctrl+C to exit the watch when all pods show "Running" status (this may take a minute or two).

### Step 4: Access Your WordPress Website

#### For Docker Desktop or Kind:
```bash
# Get information about running services
kubectl get svc

# Look for the WordPress service, which will show something like:
# wordpress   NodePort   10.96.x.x   <none>   80:30000/TCP   1m
```

Open your browser and go to: http://localhost:30000

#### For Minikube:
```bash
# Get the URL to access WordPress
minikube service wordpress --url

# Open that URL in your browser
open $(minikube service wordpress --url)
```

### Step 5: Access phpMyAdmin (Database Management)

Similar to accessing WordPress:

#### For Docker Desktop or Kind:
```bash
# Get the port for phpMyAdmin
kubectl get svc phpmyadmin
```

Look for the NodePort (e.g., 80:30001/TCP) and open http://localhost:30001 in your browser.

#### For Minikube:
```bash
# Open phpMyAdmin directly
minikube service phpmyadmin
```

## Usage

- Use the WordPress interface to set up your site.
- Use phpMyAdmin to manage your MariaDB database.

## Cleaning and Rebuilding

If you need to clean up your environment and rebuild it from scratch, follow these steps:

### Step 1: Delete All Deployed Resources

1. **Delete all resources deployed from manifests**:

   ```bash
   # Delete all resources in the manifests directory and subdirectories
   kubectl delete -f manifests/ --recursive
   ```

2. **Verify everything is removed**:

   ```bash
   # Check if any pods are still running
   kubectl get pods
   
   # Check if any services still exist
   kubectl get svc
   
   # Check if any persistent volume claims remain
   kubectl get pvc
   ```

### Step 2: Delete PersistentVolumeClaims (if they weren't removed automatically)

```bash
# List any remaining PVCs
kubectl get pvc

# Delete specific MariaDB PVC if it exists
kubectl delete pvc mariadb-pvc
```

### Step 3: Clean Kubernetes Environment (Optional)

Depending on which Kubernetes environment you're using:

#### For Docker Desktop

```bash
# Reset Kubernetes cluster in Docker Desktop
# You can do this from the Docker Desktop UI: Settings > Kubernetes > Reset Kubernetes Cluster
```

#### For Minikube

```bash
# Stop and delete the minikube cluster
minikube stop
minikube delete
```

#### For Kind

```bash
# Delete the kind cluster
kind delete cluster
```

### Step 4: Rebuild Everything

1. **If you reset your Kubernetes environment, set it up again** (follow Step 2 in the setup guide above)

2. **Deploy all resources again**:

   ```bash
   # Apply all manifests
   kubectl apply -f manifests/
   
   # Watch the deployment progress
   kubectl get pods --watch
   ```

3. **Access your services** (follow Steps 4 and 5 in the setup guide above)

## Notes

- Ensure that your Kubernetes cluster has sufficient resources to run the services.
- Modify the environment variables in the deployment files as needed for your configuration.

## License

This project is licensed under the MIT License.
