clear all;
close all;
clc;

%Variables del programa
I=7;
K=15;
ranura_sleep=18;
DIFS=10e-3;
SIFS=5e-3;
durRTS=11e-3;
durCTS=11e-3;
durACK=11e-3;
durDATA=43e-3;
dur_miniranura=1e-3;
t_sim=0;
W=16;
N=5;
tasa_paquetes=0.0005;
T=durDATA+durRTS+durCTS+DIFS+durACK+dur_miniranura*W+3*SIFS;
Tc=T*(ranura_sleep+2-I);
ciclo=1;
paquetes_descartados=0;
paquetes_transmitidos=0;
ranura=1;
colisiones_red=0;
paquete_recuperado=0;
t_arribo=0;

%Generamos los grados y nodos

grados=Grado;
nodos=Nodo;
buffer=zeros(1,K);

Ranuras=['R' 'T' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S']; %Ranuras para la calendarizacion consecutiva

for i=1:I   %Añadimos los grados a la red
grados.id=i;
grados.ranuras=Ranuras;
Grados_red(i)=grados;

for j=1:N   %Añadimos los nodos a cada grado en la red
nodos.id=j;
nodos.buffer=buffer(1,:);
Nodos_grado(j)=nodos;
end
Grados_red(i).nodos=Nodos_grado;

end






% Inicio de los ciclos

while ciclo < 100

%Generacion de paquetes cuando el ciclo sea 1 o t_arribo sea menor a t_sim

     while  t_arribo<t_sim ||ciclo==1
     tasa_paquetes=tasa_paquetes*N*I;    
     grado_aleatorio=randi([1 I],1,1) %Seleccionamos numeros aleatorios para grado y nodo aleatorio
     nodo_aleatorio=randi([1 N],1,1)

     grado_seleccionado=Grados_red(grado_aleatorio); %Obtiene grado y nodo aleatorio de las clases creadas
     nodo_seleccionado=grado_seleccionado.nodos(nodo_aleatorio);

     espacio=false;
     lugar=0;

        for i=1:length(nodo_seleccionado.buffer)

        if nodo_seleccionado.buffer(i)==0  %Comprobacion de buffer si esta lleno o hay espacio
        espacio=true;
        lugar=i;
        break
        end
     
        end

        if espacio==true  %Si hay espacio, asigna paquete a grado y nodo aleatorio

        nodo_seleccionado.buffer(lugar)=1;
        Grados_red(grado_aleatorio).nodos(nodo_aleatorio)=nodo_seleccionado;
        u=(1e6*rand)/1e6;
        nuevo_tiempo=-(1/tasa_paquetes)*log(1-u);
        t_arribo=t_sim+nuevo_tiempo; %Generamos nuevo t_arribo
   
        else %No hay espacio, se descarta el paquete

        paquetes_descartados=paquetes_descartados+1;
        Grados_red(grado_aleatorio).paquete_perdido_grado=Grados_red(grado_aleatorio).paquete_perdido_grado+1;
        u=(1e6*rand)/1e6;
        nuevo_tiempo=-(1/tasa_paquetes)*log(1-u);
        t_arribo=t_sim+nuevo_tiempo; %Se genera un nuevo t_arribo
        end

        if ciclo==1 %En el caso de se primer ciclo, genera paquete independientemiente de las condiciones  
        break;
        end

     end


    
      %t_arribo es mayor a t_sim, inicia el proceso de contención
        ranura_auxiliar=0;
        if ciclo==1
            for i=I:-1:1 %For para llenado de ranuras y que sea una trasmision consecutiva
           
            grado_actual=Grados_red(i);
            
    
            if ranura_auxiliar>0
            
            Ranuras=['S' Ranuras(1:20-1)]; %Para que siempre sea un tamaño 20
     
            end
            ranura_auxiliar=ranura_auxiliar+1;
            Grados_red(i).ranuras=Ranuras;
    
            
            end
        end
            

            if ciclo==1 || ranura>20 %Comienza la transmision desde la ranura 1
            ranura=1;
            end
            
        i=I;
        ranura_flag=true;
        transmision_flag=false;
        transmision_vacia=false;

        


        %
        while transmision_flag==false
        nodos_transmisores=[];

            while ranura_flag==true

         

            if Grados_red(i).ranuras(ranura) =='T' % En caso de no ser ranura de sleep y es una transmision

                    
        
                    for l=1:N %Verificacion de nodos y buffers que tengan paquetes que transmitir
                   
                    for t=1:K
                    if Grados_red(i).nodos(l).buffer(t)~=0
                    nodos_transmisores=[nodos_transmisores Grados_red(i).nodos(l).id];   
                    ranura_flag=false;
                    break
                    end
                    end
                    end


                    if isempty(nodos_transmisores)
                    if i==1    
                    ranura=21;
                    t_sim=t_sim+T+Tc;
                    ciclo=ciclo+1;
                    ranura_flag=false;
                    transmision_vacia=true;
                    transmision_flag=true;
                    

                    else
                    i=i-1;
                    ranura=ranura+1;
                    t_sim=t_sim+T;
                    end    
                    
                    
                    end
                 
                    


            else %No es transmision 
         
            ranura=ranura+1;

            end
            end

        %Proceso de contención

      
        if transmision_vacia==false

        contadores=[];
        nodos_contendientes=[];
        



        for l=1:length(nodos_transmisores)   %Asignamos una variable aleatoria a cada contador de cada nodo
        contador=randi([0 W-1],1,1);
        Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff=contador;
        contadores=[contadores Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff];
        
        end

        ganador=min(contadores); %Selecciona el ganador/es de el proceso de contención

            for k=1:N  %Busca si gano un solo nodo o varios
                if Grados_red(i).nodos(k).contador_backoff==ganador
                nodos_contendientes=[nodos_contendientes k]; %Variable que almacena el numero del nodo/nodos ganadores
                end

            end

        if length(nodos_contendientes)>1  %Si gano la contención mas de un nodo
        colisiones_red=colisiones_red+1;  %Aumenta numero de colisiones
        Grados_red(i).paquetes_colisionados=Grados_red(i).paquetes_colisionados+1;
        Grados_red(i).paquete_perdido_grado=Grados_red(i).paquete_perdido_grado+length(nodos_contendientes); %Aumenta perdidas de paquetes por grado y en la red
        paquetes_descartados=paquetes_descartados+length(nodos_contendientes);

            for n=1:length(nodos_contendientes)
            buffer_eliminado=Grados_red(i).nodos(n).buffer;   
                
            for b=1:K
            if buffer_eliminado(b)~=0 %Eliminamos el paquete del buffer de los nodos
               buffer_eliminado(b)=0;
               break
            end
            end
            Grados_red(i).nodos(n).buffer=buffer_eliminado;

            end
        t_sim=t_sim+T; 
        if i==1
        i=I;
        ranura=21;
        ciclo=ciclo+1;
        t_sim=t_sim+Tc; 
        transmision_flag=true;
        else
        i=i-1;
        ranura=ranura+1;
        ranura_flag=true;
        end

        
        
        else  %En el caso de solo tener un nodo 

        %Eliminamos paquete del buffer ganador
        
        buffer_eliminado=Grados_red(i).nodos(nodos_contendientes).buffer;
        for b=1:K
            if buffer_eliminado(b)~=0 %Eliminamos el paquete del buffer de los nodos
               paquete_recuperado=buffer_eliminado(b); 
               buffer_eliminado(b)=0;
               break
            end
        end
        buffer_recorrido=[];

        buffer_recorrido=[buffer_recorrido buffer_eliminado(2:K)];
        buffer_recorrido=[buffer_recorrido 0];
        Grados_red(i).nodos(nodos_contendientes).buffer=buffer_recorrido;

       
        %Comprobar si es grado 1 o cualquie otro
             if i==1  %Condicion que hace cuando es grado 1 y transmite a nodo sink
             
             paquetes_transmitidos=paquetes_transmitidos+1;
             Grados_red(i).paquete_transmitido_grado=Grados_red(i).paquete_transmitido_grado+1;
             t_sim=t_sim+T+Tc;
            
             ranura=21;
             ciclo=ciclo+1;
             
             transmision_flag=true;

        
             else 
                 
                 for t=1:K
                 if Grados_red(i-1).nodos(nodos_contendientes).buffer(t)==0
                 Grados_red(i-1).nodos(nodos_contendientes).buffer(t)=paquete_recuperado;
                 paquetes_transmitidos=paquetes_transmitidos+1;
                 break
                 else
                 paquetes_descartados=paquetes_descartados+1;
                 break
                 end
                 end 
             
             t_sim=t_sim+T;
             i=i-1;
             ranura=ranura+1;
             ranura_flag=true;
             

             end

        end
        end
        end
       

        end
 
        


        



     





    
     













