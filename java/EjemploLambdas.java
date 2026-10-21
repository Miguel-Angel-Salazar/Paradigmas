import java.util.*;
import java.util.concurrent.Callable;
import java.util.function.*;

public class EjemploLambdas{
    public static void main(String[]args)throws Exception{
        // Lista base
    List<Integer>numeros=Arrays.asList(1,2,3,4,5);

    //1.predicate

    //3 Consumer<T>
    Consumer<Integer> imprimir =n -> System.out.println("Valor:" + n);
    numeros.forEach(imprimir);
    //4
    Supplier<Double>aleatorio =() -> Math.random();
    System.out.println("Numero aleatorio:" + aleatorio.get());


    //6
    BiPredicate<Integer, Integer> mayorQue =(a,b) ->a > b;
    System.out.println("¿10 > 5?"+ mayorQue.test(10,5));

    // 7
    BiConsumer<String,Integer> mostrarPar = (nombre,edad) ->
        System.out.println(nombre + "tiene"+ edad + "año");
    mostrarPar.accept("juan",30);

    }
}