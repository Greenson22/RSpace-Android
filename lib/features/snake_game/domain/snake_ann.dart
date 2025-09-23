import 'dart:math';
import 'dart:convert'; // Ditambahkan

// Fungsi aktivasi Sigmoid
double sigmoid(double x) {
  return 1 / (1 + exp(-x));
}

class NeuralNetwork {
  late List<int> layers;
  late List<List<List<double>>> weights;

  NeuralNetwork(this.layers) {
    weights = [];
    for (int i = 0; i < layers.length - 1; i++) {
      weights.add(
        List.generate(
          layers[i + 1],
          (index) => List.generate(
            layers[i],
            (index) => Random().nextDouble() * 2 - 1,
          ),
        ),
      );
    }
  }

  // Konstruktor baru dari data bobot yang ada
  NeuralNetwork.fromWeights(this.layers, this.weights);

  // Fungsi untuk mengubah otak menjadi JSON
  Map<String, dynamic> toJson() {
    return {'layers': layers, 'weights': weights};
  }

  // Factory untuk membuat otak dari JSON
  factory NeuralNetwork.fromJson(Map<String, dynamic> json) {
    List<int> layers = List<int>.from(json['layers']);
    List<dynamic> weightsJson = json['weights'];
    List<List<List<double>>> weights = weightsJson.map((layer) {
      return (layer as List).map((neuron) {
        return (neuron as List).map((weight) => weight as double).toList();
      }).toList();
    }).toList();
    return NeuralNetwork.fromWeights(layers, weights);
  }

  List<double> predict(List<double> inputs) {
    List<double> currentOutputs = inputs;
    for (int i = 0; i < weights.length; i++) {
      List<double> layerOutputs = [];
      for (int j = 0; j < weights[i].length; j++) {
        double sum = 0;
        for (int k = 0; k < weights[i][j].length; k++) {
          sum += weights[i][j][k] * currentOutputs[k];
        }
        layerOutputs.add(sigmoid(sum));
      }
      currentOutputs = layerOutputs;
    }
    return currentOutputs;
  }

  void mutate(double mutationRate) {
    for (int i = 0; i < weights.length; i++) {
      for (int j = 0; j < weights[i].length; j++) {
        for (int k = 0; k < weights[i][j].length; k++) {
          if (Random().nextDouble() < mutationRate) {
            weights[i][j][k] += (Random().nextDouble() * 0.2 - 0.1);
          }
        }
      }
    }
  }

  static NeuralNetwork crossover(NeuralNetwork parentA, NeuralNetwork parentB) {
    NeuralNetwork child = NeuralNetwork(parentA.layers);
    for (int i = 0; i < parentA.weights.length; i++) {
      for (int j = 0; j < parentA.weights[i].length; j++) {
        for (int k = 0; k < parentA.weights[i][j].length; k++) {
          child.weights[i][j][k] = Random().nextBool()
              ? parentA.weights[i][j][k]
              : parentB.weights[i][j][k];
        }
      }
    }
    return child;
  }
}
