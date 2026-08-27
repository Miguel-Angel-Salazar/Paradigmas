//Realizar un programa en Java con programación funcional:
//1. crear empleados,
//2. filtrar por salario, área o antigüedad,
//3. calcular bonificaciones,
//4. validar si un empleado aplica a un beneficio,
//5. actualizar salarios,
//6. acumular masa salarial,
//7. ejecutar reportes.


import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.stream.Collectors;

class Empleado{
    private String nombre;
    private double salario;
    private String area;
    private int antiguedad;

    public Empleado(String nombre, double salario, String area,int antiguedad) {
        this.nombre = nombre;
        this.salario = salario;
        this.area = area;
        this.antiguedad = antiguedad;
    }

    public String getNombre(){
        return nombre;
    }

    public double getSalario(){
        return salario;
    }
    public String getArea(){
        return area;
    }

    public int getAntiguedad(){
        return antiguedad;
    }
    public void setSalario(double salario){
        this.salario = salario;
    }

    @Override
    public String toString() {
        return "Empleado{" +
            "nombre='" + nombre + '\'' +
            ", salario=" + salario +
            ", area='" + area + '\'' +
            ", antiguedad=" + antiguedad +
            '}';
    }
}

public class ejercicio_boni {

    public static void main(String[] args) throws Exception {
        List<Empleado> empleados = new ArrayList<>(Arrays.asList(
                new Empleado("MIguel Salazar", 200000, "Seguridad",3),
                new Empleado("sebastian villa", 300000, "Tecnologia", 2),
                new Empleado("Esteban", 6000000, "recursos humanos", 1),
                new Empleado("camilo", 350000, "Contador",5)
        ));

        // Supplier<T>: genera un empleado nuevo
        java.util.function.Supplier<Empleado> proveedorEmpleado =
            () -> new Empleado("Daniel", 4200000, "gerente", 3);

        Empleado nuevoEmpleado = proveedorEmpleado.get();
        empleados.add(nuevoEmpleado);

        // Predicate<T>: filtros
        java.util.function.Predicate<Empleado> salarioAlto =
            empleado -> empleado.getSalario() > 3000000;

        List<Empleado> empleadosSalarioAlto = empleados.stream()
            .filter(salarioAlto)
            .collect(Collectors.toList());

        java.util.function.Predicate<Empleado> perteneceContabilidad =
            empleado -> empleado.getArea().equalsIgnoreCase("Contabilidad");

        List<Empleado> empleadosContabilidad = empleados.stream()
            .filter(perteneceContabilidad)
            .collect(Collectors.toList());

        java.util.function.Predicate<Empleado> muchaAntiguedad =
            empleado -> empleado.getAntiguedad() >= 3;

        List<Empleado> empleadosAntiguos = empleados.stream()
            .filter(muchaAntiguedad)
            .collect(Collectors.toList());

        // BiFunction<T, U, R>: calcular bonificación
        java.util.function.BiFunction<Empleado, Integer, Double> aplicarBonificacion =
            (empleado, antiguedadMinima) -> {
                if (empleado.getAntiguedad() >= 10) {
                return empleado.getSalario() * 0.15;
                } else if (empleado.getAntiguedad() >= 5) {
                return empleado.getSalario() * 0.10;
                } else {
                return empleado.getSalario() * 0.05;
                }
            };

        Empleado empleado = empleados.get(0);
        double bonificacion = aplicarBonificacion.apply(empleado, 3);
        double salarioFinal = empleado.getSalario() + bonificacion;

        System.out.println("\nEmpleado: " + empleado.getNombre());
        System.out.println("Salario: " + empleado.getSalario());
        System.out.println("Bonificación: " + bonificacion);
        System.out.println("Salario final: " + salarioFinal);

        // Predicate<T>: validar si un empleado aplica a un beneficio
        java.util.function.Predicate<Empleado> aplicaBeneficio =
                    Empleado -> empleado.getAntiguedad() >= 5;

        if (aplicaBeneficio.test(empleado)) {
            System.out.println("\n" + empleado.getNombre() + " aplica al beneficio.");
        } else {
            System.out.println("\n" + empleado.getNombre() + " no aplica al beneficio.");
        }

        // Consumer<T>: actualizar salario
        java.util.function.Consumer<Empleado> aumentarSalario =
                Empleado -> empleado.setSalario(empleado.getSalario() * 1.10);

        System.out.println("\nSalario antes del aumento: " + empleado.getSalario());

        aumentarSalario.accept(empleado);

        System.out.println("Salario después del aumento: " + empleado.getSalario());


    }
}