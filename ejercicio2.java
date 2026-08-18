//Declarativo
import java.util.*;

public class ejercicio2 {
    public static void main(String[] args) {
        List<Integer> numeros = Arrays.asList(3,7,2,9,5);
        int max = numeros.stream()
        .max(Integer::compare)
        .get(); //obtener el valor del get
    System.out.println("Numero maximo:" + max);
    }
}
