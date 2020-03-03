#!/usr/bin/env bash
kubectl port-forward -n istio-system service/kiali 20001:20001
