// imperativo
// encontrar el numero mas de una lista

import java.util.*;

public class ejercicio {
    public static void main(String[] args) {
        List<Integer> numeros = Arrays.asList(0, 4, 5, 6, 7);
        int max = numeros.get(0); // inicializa el primer numero

    for (Integer n : numeros){
        if (n > max){
            max = n;
        }
    }
System.out.println("El numero maximo es" + max);
    }
}
