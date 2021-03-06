#' Captioner function
#'
#' Creates a function to create numbered captions for figures, tables or other objects
#' 
#' @param prefix Character string containing text to go before object number. The default is "Figure".
#' @param auto_space Logical indicating whether or not a space should automatically be added following the prefix.  Space is added by default.
#' @param levels Logical or number indicating whether or not you want hierarchical numbering, and if so, how many levels.  Hierarchical numbering is turned off by default.
#' @param type Vector with same length as `levels` indicating whether figure numbering should be numeric ("n"), lowercase character ("c"), or uppercase character ("C").  If unspecified, `captioner` will revert to all numeric values.
#' @param infix Character string containing text to go between figure numbers if hierarchical numbering is on.  Default is "."
#' 
#' @return A captioner function.
#' 
#' @details Captioner generates a function with the following parameters
#' 
#' \code{name}: Character string containing a unique object name
#' 
#' \code{caption}: The object caption
#' 
#' \code{cite}: Logical indicating whether or not you would like to generate a short form to use for in-text citation
#' 
#' \code{num}: Logical indicating whether or not you want to show the figure number only
#' 
#' \code{level}: Optional numeric used to bump up the numbering if you have hierarchical numbering.  See also \code{\link{bump}}.
#' 
#' And returns a character string containing the prefix and object number with or without a caption.
#' The initial numbering is determined based on the order of caption creation.  However, this order
#' is modified based on the citations you use.  The first figure to be cited will be moved to the
#' beginning of the list, becoming "Figure 1".
#' 
#' @examples
#' Create a new captioner object:
#' 
#' fig_nums <- captioner()
#' 
#' Store a caption with the key word "flower_plot". Print the caption
#' including the figure number:
#' 
#' fig_nums("flower_plot", "This plot shows the distribution of flower colors")
#' 
#' Cite the figure e.g. "Figure 1", using the key word:
#' 
#' fig_nums("flower_plot", cite = TRUE)
#' 
#' Now you can print the caption any time using the designated key:
#' 
#' fig_nums("flower_plot")
#'
#' Create a captioner object with hierarchical numbering:
#' 
#' tables <- captioner(prefix = "Table", levels = 2)
#' tables("a", "Table of world populations sorted from greatest to least.")
#'   
#' @export

captioner <- function(prefix = "Figure", auto_space = TRUE, levels = 1,
                      type = NULL, infix = ".")
{
  ## Make sure all of the parameters are setup correctly ---
  
  # Check the parameter classes
  check_class(prefix,     "character")
  check_class(auto_space, "logical")
  check_class(levels,     "numeric")
  check_class(infix,      "character")
  
  # Check "type" vector
  
  # Set missing/NULL "type" values to numeric
  # Cut off extra values
  if(is.null(type)){
    type <- c(rep("n", times = levels))
  } else if(length(type) < levels){
    type[(length(type) + 1):levels] <- "n"
  } else if(length(type) > levels){
    type <- type[1:levels]
  }
  
  # Give error if wrong types were used
  if(!all(type %in% c("n", "c", "C"))){
    stop("Invalid 'type' value used.  Expecting 'n', 'c', or 'C'.")
  }
  
  # Add a space after the prefix if auto_space is on
  if(auto_space){
    prefix <- paste(prefix, " ")
  }
  
  # Force the parameter values for use in the return function
  force(levels)  
  force(prefix)
  force(infix)
  
  ## Create the OBJECT list ---
  
  # Create a list to store object names, captions, and numbers
  OBJECTS <- list("name"    = NULL,
                  "caption" = NULL,
                  "number"  = list(list()))
  
  # Assign the first caption number
  # Note that extra values of "type" are ignored by looping over "levels"
  OBJECTS$number[[1]][which(type == "n")] <- 1
  OBJECTS$number[[1]][which(type == "c")] <- "a"
  OBJECTS$number[[1]][which(type == "C")] <- "A"
  
  ## Create and return the specialized captioning function ---
  
  function(name, caption = "", cite = FALSE, num = FALSE, level = FALSE)
  {
    ## Error check parameters --
    if(level > levels){
      stop("Level too large.")
    }    
    
    ## Get the object list from the enclosing environment ---
    objects <- OBJECTS
    
    ## Assign the new name and caption to the list ---
    
    # Is the name already stored?
    if(any(objects$name == name)) {
      # find the index associated with the stored name
      obj_ind <- match(name, objects$name)
      
      # find the caption associated with the stored name
      # if the caption is missing, and you supplied one with the current
      # function call, the missing one will be filled in with the new one
      if(objects$caption[obj_ind] == ""){
        # replace empty caption
        objects$caption[obj_ind] <- caption
      } else {
        # access existing caption
        caption <- objects$caption[obj_ind]
      }
    }  
    else {
      # get the earliest available index
      obj_ind <- length(objects$name) + 1
            
      # If there is already a nameless number, none will be added
      # Otherwise the number is incremented
      if(length(objects$number) == length(objects$name)){
        if(level){
          # bump the numbering at an earlier level
          objects$number[[obj_ind]] <- increment(objects$number[[obj_ind - 1]], level)
        } else{
          # increment the previous number and add as the new number
          objects$number[[obj_ind]] <- increment(objects$number[[obj_ind - 1]], levels)
          
        }
      }
      
      # store the object name and caption at the current index
      objects$name[obj_ind]    <- name
      objects$caption[obj_ind] <- caption
    }
    
    ## Copy "objects" back to the parent environment ---
    
    assign("OBJECTS", objects, envir = parent.env(environment()))
    
    ## Format the display ready output ---
    
    # create display version of object number
    obj_num <- paste(objects$number[[obj_ind]], collapse = infix)
    
    # choose between short or long format
    if(num) {
      text <- obj_num
    } else if(cite) {
      text <- paste0(prefix, obj_num)
    } else {
      text <- paste0(prefix, obj_num, ": ", caption)
    }
    
    return(text)
  }
}