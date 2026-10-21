// Imperativo
import java.util.Scanner;

public class ejercicio3 {
    public static void main(String[] args) {
        Scanner entrada = new Scanner(System.in);

        System.out.print("Primer numero: ");
        double numero1 = entrada.nextDouble();

        System.out.print("Operacion (+, -, *, /): ");
        char operacion = entrada.next().charAt(0);

        System.out.print("Segundo numero: ");
        double numero2 = entrada.nextDouble();

        double resultado;

        switch (operacion) {
            case '+':
                resultado = numero1 + numero2;
                break;
            case '-':
                resultado = numero1 - numero2;
                break;
            case '*':
                resultado = numero1 * numero2;
                break;
            case '/':
                if (numero2 == 0) {
                    System.out.println("No se puede dividir entre cero.");
                    entrada.close();
                    return;
                }
                resultado = numero1 / numero2;
                break;
            default:
                System.out.println("Operacion no valida.");
                entrada.close();
                return;
        }

        System.out.println("Resultado: " + resultado);
        entrada.close();
    }
}