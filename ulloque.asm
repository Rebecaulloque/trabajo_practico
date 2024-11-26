		.macro read_int
		li $v0,5
		syscall
		.end_macro

		.macro print_label (%label)
		la $a0, %label
		li $v0, 4
		syscall
		.end_macro

		.macro done
		li $v0,10
		syscall
		.end_macro	

		.macro print_error(%label)
  		 la $a0, %label
 		 li $v0, 4
  		 syscall
    		 print_label(return)
		.end_macro

		
		.data
slist:	.word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu:	.ascii "\nBienvenido/a, las opciones son:\n"
		.ascii "\n"
		.ascii "1-Crear categoria\n"
		.ascii "2-categoria siguiente > \n"
		.ascii "3-Categoria anterior < \n"
		.ascii "4-Listado de categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Agregar un objeto a la categoria actual\n"
		.ascii "7-Listado de objetos de la categoria actual\n"
		.ascii "8-Borrar objeto de la categoria actual\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese una opcion (solo numeros): "
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de la categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria:"
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "Accion realizada con exito!\n\n"
simbolo: .asciiz "\n> "
noEncontrado: .asciiz "\nno Encontrado\n"
error_invalid_option: .asciiz "Error: Opción no válida. Por favor, ingrese un número entre 0 y 8.\n"
error_empty_category: .asciiz "Error: No hay categorías creadas.\n"
error_no_objects: .asciiz "Error: La categoría seleccionada no tiene objetos.\n"
error_not_found: .asciiz "Error: Elemento no encontrado.\n"
error_generic: .asciiz "Error: Ocurrió un problema inesperado.\n"


		.text
main:
	la $t0, schedv # initialization scheduler vector
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcaterogy
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcaterogy
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
bucle:
	jal menu_opciones
	beqz $v0, main_end
	addi $v0, $v0, -1
	sll $v0, $v0, 2
	la $t0, schedv
	add $t0, $t0, $v0
	lw $t1, ($t0)
    	la $ra, main_ret
    	jr $t1
main_ret:
    j bucle	
main_end:
	done

menu_opciones:
	print_label(menu)
	read_int
	bgt $v0, 8, menu_opcion1
	bltz $v0, menu_opcion1
	jr $ra
menu_opcion1:
	print_error(error_invalid_option)
	j menu_opciones
	

newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName
	jal getblock
	move $a2, $v0
	la $a0, cclist
	li $a1, 0
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist
newcategory_end:
	li $v0, 0
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

nextcategory:
	lw $t0, cclist 
	beqz $t0, menu_opcion2
	lw $t1, ($t0)
	beq $t0, $t1, menu_opcion3
	lw $t0, wclist
	lw $t1, 12($t0)
	sw $t1, wclist
	j categoria_seleccionada
	
prevcaterogy:
	lw $t0, cclist 
	beqz $t0, menu_opcion2
	lw $t1, ($t0) 
	beq $t0, $t1, menu_opcion3
	lw $t0, wclist
	lw $t1, ($t0)
	sw $t1, wclist
	j categoria_seleccionada
	
categoria_seleccionada:
	print_label(selCat)
	lw $t0, wclist
	lw $t1, 8($t0)
	la $a0, ($t1)
	li $v0, 4
	syscall
	j end_selected_category
	
menu_opcion2:
	print_error(201)
	j end_selected_category
menu_opcion3:
	print_error(202)
end_selected_category:
	li $v0, 0
	jr $ra
	
listcategories:
	lw $t0, wclist
	beqz $t0, menu_opcion4
	move $t2, $t0
print_categories:
	print_label(simbolo)
	lw $t1, 8($t0)
	la $a0, ($t1)
	li $v0, 4
	syscall
	lw $t0, 12($t0)
	beq $t2, $t0, end_listcategories
	j print_categories
menu_opcion4:
	print_error(301)
end_listcategories:
	li $v0, 0
	jr $ra

delcaterogy:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist
	beqz $t0, menu_opcion5
	lw $t1, 4($t0)
	beq $t1, $0, free_category
free_objects:
	lw $a0, ($t1)
	beqz $a0, free_category
	la $a1, ($t1)
	jal delnode
	j free_objects
free_category:
	lw $t0, wclist
	li $t1, 0
	sw $t1, 4($t0)
	la $a0, ($t0)
	la $a1, cclist
	jal delnode
	lw $t0, cclist
	beqz $t0, puntero_null
	lw $t0, 12($t0)
	sw $t0, wclist
	j end_delcategory
puntero_null:
	li $t0, 0
	sw $t0, wclist
	sw $t0, cclist
	j end_delcategory
menu_opcion5:
	print_error(401)
end_delcategory:
	lw $ra, 4($sp)
	addi $sp $sp, 4
	print_label(success)
	li $v0, 0
	jr $ra

	
newobject:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist
	beqz $t0, menu_opcion6 
	la $a0, objName
	jal getblock
	move $a2, $v0
	lw $t0, wclist
	la $a0, 4($t0)
	li $a1, 1
	jal addobject
	print_label(success)
	lw $t0, wclist
	lw $t0, 4($t0)
	bnez $t0, end_newobject
	sw $v0, ($t0)
	j end_newobject
menu_opcion6:
	print_error(error_empty_category)
end_newobject: 
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	li $v0, 0
	jr $ra

addobject:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0)
	beqz $t0, addobject_empty_list
addobject_to_end:
	lw $t1, ($t0)
	lw $t2, 4($t1)
	add $a1, $a1, $t2
	sw $a1, 4($v0)
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addobject_exit
addobject_empty_list:
	sw $a1, 4($v0)
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addobject_exit:
	lw $ra, 8($sp)
	addi $sp $sp, 8
	jr $ra


listobjects:
	lw $t0, wclist
	beqz $t0, menu_opcion7 
	lw $t0, 4($t0)
	beqz $t0, menu_opcion8
	move $t2, $t0
print_objects:
	print_label(simbolo)
	lw $t1, 8($t0)
	la $a0, ($t1)
	li $v0, 4
	syscall
	lw $t0, 12($t0)
	beq $t2, $t0, end_listobjects
	j print_objects
menu_opcion7:
	print_error(601)
	j end_listobjects
menu_opcion8:
	print_error(602)
end_listobjects:
	li $v0, 0
	jr $ra

delobject:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	lw $t0, wclist
	beqz $t0, menu_opcion9
	lw $t0, 4($t0)
	beqz $t0, menu_opcion9
	move $t2, $t0
	print_label(idObj)
	read_int
busqueda_id:
	lw $t1, 4($t0)
	bne $t1, $v0, siguiente_nodo
	move $a0, $t0
	lw $t3, wclist 
	la $a1, 4($t3)
	jal delnode
	print_label(success)
	j end_delobject
siguiente_nodo:
	lw $t0, 12($t0)
	beq $t2, $t0, id_noencontrado
	j busqueda_id
menu_opcion9:
	print_error(701)
	j end_delobject
id_noencontrado:
	print_label(noEncontrado)
   	move $a0, $v0
  	li $v0, 1
   	syscall
  	j end_delobject
end_delobject:
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	li $v0, 0
	jr $ra
	

addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0)
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0)
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0)
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra


delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0)
	jal sfree
	lw $a0, 4($sp)
	lw $t0, 12($a0)
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0)
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1)
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1)
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1)
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra


getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16
	li $v0, 9
	syscall
	jr $ra

sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist
	jr $ra
